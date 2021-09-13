package why.auth;

import jsonwebtoken.*;
import jsonwebtoken.crypto.*;
import jsonwebtoken.verifier.BasicVerifier;
import haxe.DynamicAccess;

using tink.CoreApi;

class JwtAuth<Profile:Claims, User> implements why.Auth<User> {
	
	final config:JwtConfig<Profile, User>;
	
	public function new(config) {
		this.config = config;
	}
	
	public function authenticate():Promise<Option<User>> {
		return verifyToken(config).next(claims -> config.makeUser(cast claims));
	}
	
	public static function verifyToken(input:VerifyInput):Promise<Claims> {
		return input.keys.next(keys -> switch Codec.decode(input.token) {
			case Success(pair = {a: keys[_.kid] => null}):
				final list = [for(key in keys.keys()) '"$key"'].join(', ');
				new Error('[JwtAuth] key "${pair.a.kid}" not found (available keys: $list)');
			case Success({a: keys[_.kid] => key}):
				final verifier = new BasicVerifier(RS256({publicKey: key}), new DefaultCrypto(), input.options);
				verifier.verify(input.token);
			case Failure(e):
				e;
		});
	}
}

typedef JwtConfig<Profile:Claims, User> = {
	> VerifyInput,
	final makeUser:Profile->Promise<Option<User>>;
}

private typedef VerifyInput = {
	final keys:Promise<DynamicAccess<String>>;
	final token:String;
	final ?options:VerifyOptions;
}