package why;

import why.auth.Status;
import tink.state.*;

using tink.CoreApi;

interface Delegate<Profile> {
	var status(default, null):Observable<Status<Profile>>;
	function getToken():Promise<Option<String>>;
	function signOut():Promise<Noise>;
}

