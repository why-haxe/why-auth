package why;

import why.auth.Status;
import tink.state.*;

using tink.CoreApi;

interface Delegate<Credentials, Profile> {
	var status(default, null):Observable<Status<Profile>>;
	function getToken():Promise<Option<String>>;
	function signIn(credentials:Credentials):Promise<Profile>;
	function signOut():Promise<Noise>;
}

