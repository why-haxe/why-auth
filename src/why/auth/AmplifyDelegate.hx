package why.auth;

#if !aws_amplify
	#error 'The class AmplifyDelegate requires the aws-amplify library'
#end

import why.Delegate;
import aws.amplify.Amplify;
import aws.amplify.Auth;
import aws.amplify.Hub;
import tink.state.*;

using tink.CoreApi;

typedef SignInInfo = {
	username:String,
	password:String,
}

/**
 * Setup:
 * Call `AmplifyDelegate.configure` before accessing `AmplifyDelegate.instance`
 */
class AmplifyDelegate implements Delegate<SignUpInfo, SignInInfo, UserAttributes, UserAttributes> {
	
	public static var instance(default, null):AmplifyDelegate = new AmplifyDelegate();
	
	// shorthand
	public static var inst(get, never):AmplifyDelegate;
	static inline function get_inst() return instance;
	
	
	public var status(default, null):Observable<Status<User<UserAttributes, UserAttributes>>>;
	
	public static function configure(config:{region:String, userPoolId:String, appClientId:String, ?identityPoolId:String}) {
		Amplify.configure({
			Auth: {
				mandatorySignIn: true,
				region: config.region,
				userPoolId: config.userPoolId,
				userPoolWebClientId: config.appClientId,
				identityPoolId: config.identityPoolId,
			}
		});
	}
	
	function new() {
		var state = new State<Status<User<UserAttributes, UserAttributes>>>(Initializing);
		status = state.observe();
		
		function update(init = false)
			Promise.ofJsPromise(Auth.currentUserPoolUser())
				.handle(function(o) switch o {
					case Success(null):
						state.set(SignedOut);
					case Success(user):
						Promise.ofJsPromise(Auth.userAttributes(user))
							.handle(function(o) state.set(switch o {
								case Success(attrs): SignedIn(new AmplifyUser(user, [for(entry in attrs) entry.Name => entry.Value]));
								case Failure(e): Errored(e);
							}));
					case Failure(e):
						state.set(Errored(e));
				});
			
		Hub.listen('auth', {
			onHubCapsule:
				function(capsule) {
					switch capsule.payload.event {
						case 'signIn' | 'configured': update();
						case 'signOut': state.set(SignedOut);
					}
				}
		});
	}
	
	public function signUp(info:SignUpInfo):Promise<Noise> {
		return Promise.ofJsPromise(Auth.signUp(info)).noise();
	}
	
	public function signIn(credentials:SignInInfo):Promise<Noise> {
		return Promise.ofJsPromise(Auth.signIn(credentials.username, credentials.password))
			.next(user -> {
				if((cast user).challengeName == 'NEW_PASSWORD_REQUIRED')
					Promise.ofJsPromise(Auth.completeNewPassword(user, credentials.password)).noise();
				else
					Promise.NOISE;
			});
	}
	
	public function signOut():Promise<Noise> {
		return Promise.ofJsPromise(Auth.signOut());
	}
	
	public function forgetPassword(id:String):Promise<Noise> {
		return Promise.ofJsPromise(Auth.forgotPassword(id)).noise();
	}
	
	public function resetPassword(id:String, code:String, password:String):Promise<Noise> {
		return Promise.ofJsPromise(Auth.forgotPasswordSubmit(id, code, password)).noise();
	}
	
	public function confirmSignUp(id:String, code:String):Promise<Noise> {
		return Promise.ofJsPromise(Auth.confirmSignUp(id, code)).noise();
	}
	
}

class AmplifyUser implements User<UserAttributes, UserAttributes> {
	public var profile(default, null):Observable<UserAttributes>;
	var user:CognitoUser;
	
	public function new(user, attrs) {
		this.user = user;
		profile = new State(attrs); // TODO: update when needed
	}
	
	public function getToken():Promise<String> {
		return Promise.ofJsPromise(Auth.userSession(user))
			.next(session -> session.idToken.jwtToken);
	}
	
	public function updateProfile(patch:UserAttributes):Promise<Noise> {
		return Promise.ofJsPromise(user.updateAttributes([for(key in patch.keys()) {Name: key, Value: patch[key]}])).noise();
	}
	
	public function changePassword(oldPassword:String, newPassword:String):Promise<Noise> {
		return Promise.ofJsPromise(Auth.changePassword(user, oldPassword, newPassword)).noise();
	}
}

@:forward(keys)
abstract UserAttributes(Map<String, String>) from Map<String, String> to Map<String, String> {
	@:resolve @:arrayAccess
	public inline function get(key:String):String return this.get(key);
}