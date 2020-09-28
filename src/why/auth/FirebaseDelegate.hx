package why.auth;

import firebase.auth.Auth;
import tink.state.*;
import why.Delegate;

using tink.CoreApi;

class FirebaseDelegate extends DelegateBase<Credentials, Credentials, FirebaseProfile, FirebaseProfilePatch> {
	var auth:Auth;
	
	public function new(auth) {
		var state = new State<Status<User<FirebaseProfile, FirebaseProfilePatch>>>(Initializing);
		super(state);
		this.auth = auth;
		auth.onAuthStateChanged(
			function(user) state.set(user == null ? SignedOut : SignedIn(new FirebaseUser(user))),
			function(e) state.set(Errored(Error.ofJsError(e)))
		);
	}
	
	override function signUp(credentials:Credentials):Promise<Noise> {
		return switch credentials {
			case Email(email, password):
				Promise.ofJsPromise(auth.createUserWithEmailAndPassword(email, password))
					.next(cred -> cred.user.sendEmailVerification());
		}
	}
	override function signIn(credentials:Credentials):Promise<Noise> {
		return switch credentials {
			case Email(email, password):
				Promise.ofJsPromise(auth.signInWithEmailAndPassword(email, password));
		}
	}
	
	override function signOut():Promise<Noise> {
		return Promise.ofJsPromise(auth.signOut());	
	}
	
	override function forgetPassword(id:String):Promise<Noise> {
		return Promise.ofJsPromise(auth.sendPasswordResetEmail(id));
	}
	
	override function resetPassword(id:String, code:String, password:String):Promise<Noise> {
		return Promise.ofJsPromise(auth.confirmPasswordReset(code, password));
	}
	
	override function confirmSignUp(id:String, code:String):Promise<Noise> {
		// the verification link will do the job
		return new Error('Firebase does not support this API');
	}
	
}

enum Credentials {
	Email(email:String, password:String);
}

class FirebaseUser implements User<FirebaseProfile, FirebaseProfilePatch> {
	public final profile:Observable<FirebaseProfile>;
	
	final user:firebase.User;
	
	public function new(user) {
		this.user = user;
		profile = new State(getProfile()); // TODO: update when needed
	}
	
	inline function getProfile():FirebaseProfile {
		return {
			displayName: user.displayName,
			email: user.email,
			emailVerified: user.emailVerified,
			isAnonymous: user.isAnonymous,
			metadata: user.metadata,
			phoneNumber: user.phoneNumber,
			photoURL: user.photoURL,
			providerData: user.providerData,
			providerId: user.providerId,
			refreshToken: user.refreshToken,
			// tenantId: user.tenantId,
			uid: user.uid,
		}
	}
	
	public function getToken():Promise<String> {
		return Promise.ofJsPromise(user.getIdToken());
	}
	
	public function updateProfile(patch:FirebaseProfilePatch):Promise<Noise> {
		return Promise.ofJsPromise(user.updateProfile(patch));
	}
	
	public function changePassword(oldPassword:String, newPassword:String):Promise<Noise> {
		// TODO: reauthenticateWithCredential may be required
		return Promise.ofJsPromise(user.updatePassword(newPassword));
	}
	
}

typedef FirebaseProfile = {
	displayName:String,
	email:String,
	emailVerified:Bool,
	isAnonymous:Bool,
	metadata:Dynamic,
	phoneNumber:String,
	photoURL:String,
	providerData:Dynamic,
	providerId:String,
	refreshToken:String,
	// tenantId:String,
	uid:String,
}
typedef FirebaseProfilePatch = {
	?displayName:String,
	?photoURL:String,
}