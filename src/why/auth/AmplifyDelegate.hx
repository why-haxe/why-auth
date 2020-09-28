package why.auth;

#if !aws_amplify
	#error 'The class AmplifyDelegate requires the aws-amplify library'
#end

import aws.amplify.Amplify;
import aws.amplify.Auth;
import aws.amplify.Hub;
import tink.state.*;
import why.Delegate;

using tink.CoreApi;

typedef SignInInfo = {
	username:String,
	password:String,
}

/**
 * Setup:
 * Call `AmplifyDelegate.configure` before accessing `AmplifyDelegate.instance`
 */
class AmplifyDelegate extends DelegateBase<SignUpInfo, SignInInfo, UserAttributes, UserAttributes> {
	
	public static final instance:AmplifyDelegate = new AmplifyDelegate();
	
	// shorthand
	public static var inst(get, never):AmplifyDelegate;
	static inline function get_inst() return instance;
	
	
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
		super(state);
		
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
					case Failure(e) if(e.data == 'No current user'):
						state.set(SignedOut);
					case Failure(e):
						state.set(Errored(e));
				});
			
		Hub.listen('auth', 
			function(capsule) {
				switch capsule.payload.event {
					case v = 'signIn' | 'configured': update();
					case 'signOut': state.set(SignedOut);
				}
			}
		);
	}
	
	override function signUp(info:SignUpInfo):Promise<Noise> {
		return Promise.ofJsPromise(Auth.signUp(info)).noise();
	}
	
	override function signIn(credentials:SignInInfo):Promise<Noise> {
		return Promise.ofJsPromise(Auth.signIn(credentials.username, credentials.password))
			.next(user -> {
				if((cast user).challengeName == 'NEW_PASSWORD_REQUIRED')
					Promise.ofJsPromise(Auth.completeNewPassword(user, credentials.password)).noise();
				else
					Promise.NOISE;
			});
	}
	
	override function signOut():Promise<Noise> {
		return Promise.ofJsPromise(Auth.signOut());
	}
	
	override function forgetPassword(id:String):Promise<Noise> {
		return Promise.ofJsPromise(Auth.forgotPassword(id)).noise();
	}
	
	override function resetPassword(id:String, code:String, password:String):Promise<Noise> {
		return Promise.ofJsPromise(Auth.forgotPasswordSubmit(id, code, password)).noise();
	}
	
	override function confirmSignUp(id:String, code:String):Promise<Noise> {
		return Promise.ofJsPromise(Auth.confirmSignUp(id, code)).noise();
	}
	
}

class AmplifyUser implements User<UserAttributes, UserAttributes> {
	public final profile:Observable<UserAttributes>;
	final user:CognitoUser;
	
	public function new(user, attrs) {
		this.user = user;
		profile = new State(attrs); // TODO: update when needed
	}
	
	public function getToken():Promise<String> {
		return Promise.ofJsPromise(Auth.userSession(user))
			.next(session -> session.idToken.jwtToken);
	}
	
	public function updateProfile(patch:UserAttributes):Promise<Noise> {
		return Promise.ofJsPromise(user.updateAttributes([for(key in patch.keys()) {Name: key, Value: patch.get(key)}])).noise();
	}
	
	public function changePassword(oldPassword:String, newPassword:String):Promise<Noise> {
		return Promise.ofJsPromise(Auth.changePassword(user, oldPassword, newPassword)).noise();
	}
}

@:forward(keys, keyValueIterator, iterator)
abstract UserAttributes(Map<String, String>) from Map<String, String> to Map<String, String> {
	@:resolve @:arrayAccess
	public inline function get(key:String):String return this.get(key);
}