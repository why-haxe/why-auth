package why.auth;

#if !aws_amplify
	#error 'The class AmplifyDelegate requires the aws-amplify library'
#end

import aws.amplify.Auth;
import aws.amplify.Hub;
import tink.state.*;

using tink.CoreApi;

/**
 * Setup:
 * Call `aws.amplify.Amplify.configure` before using this class
 * You can also use the macro helper to parse the downloaded `aws-exports.js` file
 * e.g. `Amplify.configure(Macro.parseConfig('aws-exports.js')`
 */
class AmplifyDelegate implements Delegate<UserInfo> {
	
	public static var INSTANCE(get, null):AmplifyDelegate;
	static function get_INSTANCE() {
		if(INSTANCE == null) INSTANCE = new AmplifyDelegate();
		return INSTANCE;
	}
	public var status(default, null):Observable<Status<UserInfo>>;
	
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
				function(capsule) switch capsule.payload.event {
					case 'signIn': update();
					case 'signOut': state.set(SignedOut);
				}
		});
		
		update();
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