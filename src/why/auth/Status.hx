package why.auth;

using tink.CoreApi;

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
}