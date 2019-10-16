package why.auth;

import jsonwebtoken.Claims;
import jsonwebtoken.verifier.BasicVerifier;
import why.auth.JwkAuth;

using tink.CoreApi;

class Auth0Auth<User> extends JwkAuth<Auth0Profile, User>{
	
	public function new(config:Auth0Config<User>) {
		super({
			makeUser: config.makeUser,
			jwkUrl: 'https://${config.domain}/.well-known/jwks.json',
			token: config.token,
			options: {
				iss: 'https://${config.domain}/',
				aud: config.clientId,
			},
		});
	}
	
	public static inline function verifyToken<User>(input:VerifyInput):Promise<Claims> {
		return JwkAuth.verifyToken({
			jwkUrl: 'https://${input.domain}/.well-known/jwks.json',
			token: input.token,
			options: {
				iss: 'https://${input.domain}/',
				aud: input.clientId,
			},
		});
	}
}

typedef Auth0Profile = {
	> Claims,
	nickname:String,
	name:String,
	picture:String,
	updated_at:String,
	email:String,
	email_verified:Bool,
	nonce:String,
}

typedef Auth0Config<User> = {
	> VerifyInput,
	var makeUser(default, null):Auth0Profile->Promise<Option<User>>;
}

private typedef VerifyInput = {
	var domain(default, null):String;
	var clientId(default, null):String;
	var token(default, null):String;
}