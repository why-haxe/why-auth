package why.auth;

import jsonwebtoken.*;
import jsonwebtoken.crypto.*;
import jsonwebtoken.verifier.*;
import haxe.DynamicAccess;

using tink.CoreApi;

class FirebaseAuth<User> extends JwtAuth<FirebaseProfile, User> {
	
	static var keys:Void->Promise<DynamicAccess<String>> = 
		Promise.cache(() -> {
			tink.http.Fetch.fetch('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com').all()
				.next(res -> tink.Json.parse((res.body:DynamicAccess<String>)))
				.next(keys -> new Pair(keys, (cast Future.NEVER:Future<Noise>)));
		});
	
	public function new(config:FirebaseConfig<User>) {
		super({
			makeUser: config.makeUser,
			keys: keys(),
			token: config.token,
			options: {
				iss: 'https://securetoken.google.com/${config.projectId}',
				aud: config.projectId,
			},
		});
	}
	
	public static function verifyToken(input:VerifyInput):Promise<Claims> {
		return JwtAuth.verifyToken({
			keys: keys(),
			token: input.token,
			options: {
				iss: 'https://securetoken.google.com/${input.projectId}',
				aud: input.projectId,
			},
		});
	}
	
}

typedef FirebaseProfile = {
	> Claims,
}

typedef FirebaseConfig<User> = {
	> VerifyInput,
	var makeUser(default, null):FirebaseProfile->Promise<Option<User>>;
}

private typedef VerifyInput = {
	var projectId(default, null):String;
	var token(default, null):String;
}