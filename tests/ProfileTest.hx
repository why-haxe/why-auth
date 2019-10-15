package;

import tink.state.*;
import why.auth.Status;
import why.Delegate;

using tink.CoreApi;

@:asserts
class ProfileTest {
	public function new() {}
	
	public function profile() {
		var status = new State(Initializing);
		var delegate = @:privateAccess new DelegateBase(status);
		var user = new TestUser();
		
		asserts.assert(delegate.profile.value.match(None));
		status.set(SignedIn(user));
		asserts.assert(delegate.profile.value.match(Some(0)));
		user.state.set(1);
		asserts.assert(delegate.profile.value.match(Some(1)));
		status.set(SignedOut);
		asserts.assert(delegate.profile.value.match(None));
		user.state.set(2);
		asserts.assert(delegate.profile.value.match(None));
		status.set(SignedIn(user));
		asserts.assert(delegate.profile.value.match(Some(2)));
		
		return asserts.done();
	}
}

private class TestUser implements User<Int, Noise> {
	public var profile(default, null):Observable<Int>;
	public var state(default, null):State<Int>;
	
	public function new() {
		profile = state = new State(0);
	}
	
	public function getToken():Promise<String> throw 'unused';
	public function updateProfile(patch:Noise):Promise<Noise> throw 'unused';
	public function changePassword(oldPassword:String, newPassword:String):Promise<Noise> throw 'unused';
}