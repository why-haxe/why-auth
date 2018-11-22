package why.auth;

import jsonwebtoken.*;
import jsonwebtoken.crypto.*;
import jsonwebtoken.verifier.*;
import haxe.DynamicAccess;

using tink.CoreApi;

class CognitoAuth<User> implements why.Auth<User> {
	
	static var jwk:Map<String, Promise<Map<String, String>>>;
	
	var makeUser:CognitoProfile->Promise<Option<User>>;
	var region:String;
	var poolId:String;
	var clientId:String;
	var idToken:String;
	
	public function new(config) {
		this.makeUser = config.makeUser;
		this.region = config.region;
		this.poolId = config.poolId;
		this.clientId = config.clientId;
		this.idToken = config.idToken;
		
		var key = jwkCacheKey();
		if(!jwk.exists(key)) {
			jwk[key] = Promise.lazy(() -> {
				tink.http.Fetch.fetch('https://cognito-idp.$region.amazonaws.com/$poolId/.well-known/jwks.json').all()
					.next(res -> tink.Json.parse((res.body:{keys:Array<{kid:String, n:String, e:String, kty:String, use:String}>})))
					.next(o -> [for(e in o.keys) e.kid => js.Lib.require('jwk-to-pem')(e)]); // TODO: haxe implementation of jwk-to-pem
			});
		}
	}
	
	public function authenticate():Promise<Option<User>> {
		return verifyToken(idToken).next(claims -> makeUser(cast claims));
	}
	
	function verifyToken(token:String):Promise<Claims> {
		return jwk[jwkCacheKey()].next(keys -> {
			switch Codec.decode(token) {
				case Success({a: keys[_.kid] => null}):
					new Error('key not found');
				case Success({a: keys[_.kid] => key}):
					var crypto = new NodeCrypto();
					var verifier = new BasicVerifier(
						RS256({publicKey: key}),
						crypto,
						{
							iss: 'https://cognito-idp.$region.amazonaws.com/$poolId',
							aud: clientId,
						}
					);
					verifier.verify(token);
				case Failure(e):
					e;
			}
		});
	}
	
	inline function jwkCacheKey()
		return '$region:$poolId';
}

typedef CognitoProfile = DynamicAccess<Dynamic>;