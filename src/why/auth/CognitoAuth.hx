package why.auth;

import jsonwebtoken.*;
import jsonwebtoken.crypto.*;
import jsonwebtoken.verifier.*;
import haxe.DynamicAccess;

using tink.CoreApi;

/**
 * Cognito User Pool
 */
class CognitoAuth<User> implements why.Auth<User> {
	
	static var jwk:Map<String, Void->Promise<Map<String, String>>> = new Map();
	
	var makeUser:CognitoProfile->Promise<Option<User>>;
	public var region(default, null):String;
	public var poolId(default, null):String;
	public var clientId(default, null):String;
	public var idToken(default, null):String;
	
	public function new(config) {
		this.makeUser = config.makeUser;
		this.region = config.region;
		this.poolId = config.poolId;
		this.clientId = config.clientId;
		this.idToken = config.idToken;
	}
	
	public function authenticate():Promise<Option<User>> {
		return verifyToken(this).next(claims -> makeUser(cast claims));
	}
	
	public static function verifyToken(o:VerifyInput):Promise<Claims> {
		
		var cache = '${o.region}:${o.poolId}';
		if(!jwk.exists(cache)) {
			jwk[cache] = Promise.cache(() -> {
				tink.http.Fetch.fetch('https://cognito-idp.${o.region}.amazonaws.com/${o.poolId}/.well-known/jwks.json').all()
					.next(res -> tink.Json.parse((res.body:{keys:Array<{kid:String, n:String, e:String, kty:String, use:String}>})))
					.next(o -> [for(e in o.keys) e.kid => js.Lib.require('jwk-to-pem')(e)]) // TODO: haxe implementation of jwk-to-pem
					.next(keys -> new Pair(keys, (cast Future.NEVER:Future<Noise>)));
			});
		}
		
		return jwk[cache]().next(keys -> {
			switch Codec.decode(o.idToken) {
				case Success({a: keys[_.kid] => null}):
					new Error('[CognitoAuth] key not found');
				case Success({a: keys[_.kid] => key}):
					var crypto = new DefaultCrypto();
					var verifier = new BasicVerifier(
						RS256({publicKey: key}),
						crypto,
						{
							iss: 'https://cognito-idp.${o.region}.amazonaws.com/${o.poolId}',
							aud: o.clientId,
						}
					);
					verifier.verify(o.idToken);
				case Failure(e):
					e;
			}
		});
	}
}

@:forward
abstract CognitoProfile(CognitoProfileObj) from CognitoProfileObj to CognitoProfileObj {
	@:arrayAccess
	public inline function resolve(key:String):String return Reflect.field(this, key);
}

typedef CognitoProfileObj = {
	> Claims,
	?email:String,
	?phone_number:String,
}

typedef VerifyInput = {
	var region(default, null):String;
	var poolId(default, null):String;
	var clientId(default, null):String;
	var idToken(default, null):String;
}