package why.auth;

import tink.state.*;
using tink.CoreApi;

class DummyDelegate<Credentials, Info> implements Delegate<Credentials, Info> {
	public var status(default, null):Observable<Status<Info>>;
	
	var state:State<Status<Info>>;
	var credentials:Credentials;
	var getInfo:Credentials->Info;
	var _getToken:Credentials->Promise<String>;
	
	public function new(getInfo, getToken, ?init) {
		this.credentials = init;
		this.getInfo = getInfo;
		this._getToken = getToken;
		state = new State<Status<Info>>(Initializing);
		status = state.observe();
		update();
	}
	
	function update() {
		state.set(credentials == null ? SignedOut : SignedIn(getInfo(credentials)));
	}
	
	public function signIn(credentials:Credentials):Promise<Info> {
		this.credentials = credentials;
		update();
		return getInfo(credentials);
	}
	
	public function signOut():Promise<Noise> {
		credentials = null;
		update();
		return Promise.NOISE;
	}
	
	public function getToken():Promise<Option<String>> {
		return credentials == null ? None : _getToken(credentials).next(Some);
	}
}