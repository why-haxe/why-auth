package why;

import why.auth.Status;
import tink.state.*;

using tink.CoreApi;

@:forward
abstract Delegate<S, C, P, T>(DelegateObject<S, C, P, T>) from DelegateObject<S, C, P, T> {
	@:from
	public static inline function ofPromise<S, C, P, T>(promise:Promise<Delegate<S, C, P, T>>):Delegate<S, C, P, T> {
		return new PromiseDelegate(promise);
	}
}
interface DelegateObject<SignUpInfo, Credentials, Profile, ProfilePatch> {
	final status:Observable<Status<User<Profile, ProfilePatch>>>;
	final profile:Observable<Option<Profile>>;
	function signUp(info:SignUpInfo):Promise<Noise>;
	function signIn(credentials:Credentials):Promise<Noise>;
	function signOut():Promise<Noise>;

	function forgetPassword(id:String):Promise<Noise>;
	function resetPassword(id:String, code:String, password:String):Promise<Noise>;
	function confirmSignUp(id:String, code:String):Promise<Noise>;
}

interface User<Profile, ProfilePatch> {
	final profile:Observable<Profile>;
	function getToken():Promise<String>;
	function updateProfile(patch:ProfilePatch):Promise<Noise>;
	function changePassword(oldPassword:String, newPassword:String):Promise<Noise>;
}

class PromiseDelegate<SignUpInfo, Credentials, Profile, ProfilePatch> extends DelegateBase<SignUpInfo, Credentials, Profile, ProfilePatch> {
	final promise:Promise<Delegate<SignUpInfo, Credentials, Profile, ProfilePatch>>;
	public function new(promise) {
		super(
			Observable
				.ofPromise(this.promise = promise)
				.map(function(promised) return switch promised {
					case Loading:
						Observable.const(Initializing);
					case Done(delegate):
						delegate.status;
					case Failed(e):
						Observable.const(Errored(e));
				})
				.flatten()
		);
	}
	
	override function signUp(info:SignUpInfo):Promise<Noise>
		return promise.next(delegate -> delegate.signUp(info));

	override function signIn(credentials:Credentials):Promise<Noise>
		return promise.next(delegate -> delegate.signIn(credentials));

	override function signOut():Promise<Noise>
		return promise.next(delegate -> delegate.signOut());

	override function forgetPassword(id:String):Promise<Noise>
		return promise.next(delegate -> delegate.forgetPassword(id));

	override function resetPassword(id:String, code:String, password:String):Promise<Noise>
		return promise.next(delegate -> delegate.resetPassword(id, code, password));

	override function confirmSignUp(id:String, code:String):Promise<Noise>
		return promise.next(delegate -> delegate.confirmSignUp(id, code));
}

// TODO: abstract class
class DelegateBase<SignUpInfo, Credentials, Profile, ProfilePatch> implements DelegateObject<SignUpInfo, Credentials, Profile, ProfilePatch> {
	public final status:Observable<Status<User<Profile, ProfilePatch>>>;
	public final profile:Observable<Option<Profile>>;

	function new(status) {
		this.status = status;
		this.profile = Observable.auto(() -> switch status.value {
			case SignedIn(user): Some(user.profile.value);
			case _: None;
		});
	}

	public function signUp(info:SignUpInfo):Promise<Noise>
		throw 'abstract';

	public function signIn(credentials:Credentials):Promise<Noise>
		throw 'abstract';

	public function signOut():Promise<Noise>
		throw 'abstract';

	public function forgetPassword(id:String):Promise<Noise>
		throw 'abstract';

	public function resetPassword(id:String, code:String, password:String):Promise<Noise>
		throw 'abstract';

	public function confirmSignUp(id:String, code:String):Promise<Noise>
		throw 'abstract';

}