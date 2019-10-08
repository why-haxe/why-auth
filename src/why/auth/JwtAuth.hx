package why.auth;

import jsonwebtoken.*;
import jsonwebtoken.crypto.*;
import jsonwebtoken.verifier.BasicVerifier;
import haxe.DynamicAccess;

using tink.CoreApi;

class JwtAuth<Profile:Claims, User> implements why.Auth<User> {
	
	var config:JwtConfig<Profile, User>;
	
	public function new(config) {
		this.config = config;
	}
	
	public function authenticate():Promise<Option<User>> {
		return verifyToken(config).next(claims -> config.makeUser(cast claims));
	}
	
	public static function verifyToken(input:VerifyInput):Promise<Claims> {
		return input.keys.next(keys -> switch Codec.decode(input.token) {
			case Success({a: keys[_.kid] => null}):
				new Error('[JwtAuth] key not found');
			case Success({a: keys[_.kid] => key}):
				var verifier = new BasicVerifier(RS256({publicKey: key}), new DefaultCrypto(), input.options);
				verifier.verify(input.token);
			case Failure(e):
				e;
		});
	}
}

typedef JwtConfig<Profile:Claims, User> = {
	> VerifyInput,
	var makeUser(default, null):Profile->Promise<Option<User>>;
}

private typedef VerifyInput = {
	var keys(default, null):Promise<DynamicAccess<String>>;
	var token(default, null):String;
	@:optional var options(default, null):VerifyOptions;
}