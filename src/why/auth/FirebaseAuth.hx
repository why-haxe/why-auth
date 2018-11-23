package why.auth;

import jsonwebtoken.*;
import jsonwebtoken.crypto.*;
import jsonwebtoken.verifier.*;
import haxe.DynamicAccess;

using tink.CoreApi;

class FirebaseAuth<User> implements why.Auth<User> {
	
	static var keys:Promise<DynamicAccess<String>> = 
		Promise.lazy(() -> {
			tink.http.Fetch.fetch('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com').all()
				.next(res -> tink.Json.parse((res.body:DynamicAccess<String>)));
		});
	
	var makeUser:String->Promise<Option<User>>;
	var projectId:String;
	var idToken:String;
	
	public function new(config) {
		this.makeUser = config.makeUser;
		this.projectId = config.projectId;
		this.idToken = config.idToken;
	}
	
	public function authenticate():Promise<Option<User>> {
		return verifyToken(idToken).next(claims -> makeUser((cast claims:DynamicAccess<String>)['sub']));
	}
	
	inline function verifyToken(token:String):Promise<Claims> {
		return keys.next(keys -> {
			switch Codec.decode(token) {
				case Success({a: keys[_.kid] => null}):
					new Error('key not found');
				case Success({a: keys[_.kid] => key}):
					var crypto = new DefaultCrypto();
					var verifier = new BasicVerifier(
						RS256({publicKey: key}),
						crypto,
						{
							iss: 'https://securetoken.google.com/$projectId',
							aud: projectId,
						}
					);
					verifier.verify(token);
				case Failure(e):
					e;
			}
		});
	}
	
}

typedef FirebaseProfile = DynamicAccess<String>;