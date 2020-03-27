package why.auth;

using tink.CoreApi;

@:using(why.auth.Status.StatusTools)
enum Status<Profile> {
	Initializing;
	SignedOut;
	SignedIn(profile:Profile);
	Errored(e:Error);
}

class StatusTools {
	public static function map<P, R>(status:Status<P>, f:P->R):Status<R> {
		return switch status {
			case Initializing: Initializing;
			case SignedOut: SignedOut;
			case SignedIn(profile): SignedIn(f(profile));
			case Errored(e): Errored(e);
		}
	}
	
	public static function next<P, R>(status:Status<P>, f:Next<P, R>):Promise<R> {
		return switch status {
			case SignedIn(profile): f(profile);
			case Errored(e): Promise.lift(e);
			case _: Promise.NEVER;
		}
	}
	
	public static function toOption<P>(status:Status<P>):Option<P> {
		return switch status {
			case SignedIn(profile): Some(profile);
			case _: None;
		}
	}
}

#if tink_state
class ObservableStatusTools {
	public static function postprocess<P, R>(observable:tink.state.Observable<Status<P>>, f:P->Promise<R>):tink.state.Observable<Status<R>> {
		var last = switch observable.value {
			case Initializing: Initializing;
			case Errored(e):  Errored(e);
			case _: SignedOut;
		}
		return observable
			.mapAsync(function(status) return switch status {
				case Initializing:
					Future.sync(last = Initializing);
				case SignedOut:
					Future.sync(last = SignedOut);
				case SignedIn(profile):
					f(profile).map(function(o) return switch o {
						case Success(v): SignedIn(v);
						case Failure(e): Errored(e);
					});
				case Errored(e):
					Future.sync(last = Errored(e));
			})
			.map(promised -> switch promised {
				case Loading: last;
				case Done(v): v;
				case Failed(e): why.auth.Status.Errored(e);
			});
	}
}
#end