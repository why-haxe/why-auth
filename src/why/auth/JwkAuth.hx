package why.auth;

import jsonwebtoken.*;
import jsonwebtoken.crypto.*;
import jsonwebtoken.verifier.BasicVerifier;
import haxe.DynamicAccess;

using tink.CoreApi;

class JwkAuth<Profile:Claims, User> extends JwtAuth<Profile, User> {
	
	static var jwks:Map<String, Void->Promise<DynamicAccess<String>>> = new Map();
	
	public function new(config:JwkConfig<Profile, User>) {
		super({
			makeUser: config.makeUser,
			keys: getJwk(config.jwkUrl),
			token: config.token,
			options: config.options,
		});
	}
	
	static function getJwk(url:String):Promise<DynamicAccess<String>> {
		if(!jwks.exists(url)) {
			jwks[url] = Promise.cache(() -> {
				tink.http.Fetch.fetch(url).all()
					.next(res -> tink.Json.parse((res.body:{keys:Array<{kid:String, n:String, e:String, kty:String, use:String}>})))
					.next(o -> {
						var keys = new DynamicAccess<String>();
						for(e in o.keys) keys[e.kid] = js.Lib.require('jwk-to-pem')(e); // TODO: haxe implementation of jwk-to-pem
						keys;
					})
					.next(keys -> new Pair(keys, (cast Future.NEVER:Future<Noise>)));
			});
		}
		return jwks[url]();
	}
	
	public static function verifyToken(input:VerifyInput):Promise<Claims> {
		return JwtAuth.verifyToken({
			keys: getJwk(input.jwkUrl),
			token: input.token,
			options: input.options,
		});
	}
}

typedef JwkConfig<Profile:Claims, User> = {
	> VerifyInput,
	var makeUser(default, null):Profile->Promise<Option<User>>;
}

private typedef VerifyInput = {
	var jwkUrl(default, null):String;
	var token(default, null):String;
	@:optional var options(default, null):VerifyOptions;
}