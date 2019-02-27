package why.auth;

#if !aws_amplify
	#error 'The class AmplifyDelegate requires the aws-amplify library'
#end

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
class AmplifyDelegate implements Delegate<SignInInfo, UserInfo> {
	
	public static var instance(get, null):AmplifyDelegate;
	static function get_instance() {
		if(instance == null) instance = new AmplifyDelegate();
		return instance;
	}
	
	// shorthand
	public static var inst(get, never):AmplifyDelegate;
	static inline function get_inst() return instance;
	
	
	public var status(default, null):Observable<Status<UserInfo>>;
	
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
		var state = new State<Status<UserInfo>>(Initializing);
		status = state.observe();
		
		function update()
			Promise.ofJsPromise(Auth.currentUserInfo())
				.handle(function(o) switch o {
					case Success(null): state.set(SignedOut);
					case Success(user): state.set(SignedIn(user));
					case Failure(e): state.set(Errored(e));
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
		update();
	}
	
	public function signIn(credentials:SignInInfo):Promise<UserInfo> {
		return Promise.ofJsPromise(Auth.signIn(credentials.username, credentials.password))
			.next(user -> {
				if(user.challengeName == 'NEW_PASSWORD_REQUIRED')
					Promise.ofJsPromise(Auth.completeNewPassword(user, credentials.password)).noise();
				else
					Promise.NOISE;
			})
			.next(_ -> Promise.ofJsPromise(Auth.currentUserInfo()));
	}
	
	public function signOut():Promise<Noise> {
		return Promise.ofJsPromise(Auth.signOut());
	}
	
	public function getToken():Promise<Option<String>> {
		return Promise.ofJsPromise(Auth.currentSession())
			.next(s -> switch s.idToken.jwtToken {
				case null: None;
				case v: Some(v);
			});
	}
}