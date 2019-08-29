package why.auth;

import firebase.User;
import firebase.auth.Auth;
import tink.state.*;
using tink.CoreApi;

class FirebaseDelegate implements Delegate<Credentials, User> {
	public var status(default, null):Observable<Status<User>>;
	
	var auth:Auth;
	
	public function new(auth) {
		this.auth = auth;
		var state = new State<Status<User>>(Initializing);
		auth.onAuthStateChanged(
			function(user) state.set(user == null ? SignedOut : SignedIn(user)),
			function(e) state.set(Errored(Error.ofJsError(e)))
		);
		status = state.observe();
	}
	
	public function signIn(credentials:Credentials):Promise<User> {
		return switch credentials {
			case Email(email, password):
				Promise.ofJsPromise(auth.signInWithEmailAndPassword(email, password))
					.next(cred -> cred.user);
		}
	}
	
	public function signOut():Promise<Noise> {
		return Promise.ofJsPromise(auth.signOut());
		
	}
	
	public function getToken():Promise<Option<String>> {
		return switch status.value {
			case SignedIn(user): Promise.ofJsPromise(user.getIdToken()).next(Some);
			case _: Promise.resolve(None);
		}
	}
}

enum Credentials {
	Email(email:String, password:String);
}