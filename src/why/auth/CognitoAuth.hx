package why.auth;

import jsonwebtoken.Claims;
import jsonwebtoken.verifier.BasicVerifier;
import why.auth.JwkAuth;

using tink.CoreApi;

class CognitoAuth<User> extends JwkAuth<CognitoProfile, User>{
	
	public function new(config:CognitoConfig<User>) {
		var domain = 'https://cognito-idp.${config.region}.amazonaws.com/${config.poolId}';
		super({
			makeUser: config.makeUser,
			jwkUrl: '$domain/.well-known/jwks.json',
			token: config.token,
			options: {
				iss: domain,
				aud: config.clientId,
			},
		});
	}
	
	public static inline function verifyToken<User>(input:VerifyInput):Promise<Claims> {
		var domain = 'https://cognito-idp.${input.region}.amazonaws.com/${input.poolId}';
		return JwkAuth.verifyToken({
			jwkUrl: '$domain/.well-known/jwks.json',
			token: input.token,
			options: {
				iss: domain,
				aud: input.clientId,
			},
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

typedef CognitoConfig<User> = {
	> VerifyInput,
	var makeUser(default, null):CognitoProfile->Promise<Option<User>>;
}

private typedef VerifyInput = {
	var region(default, null):String;
	var poolId(default, null):String;
	var clientId(default, null):String;
	var token(default, null):String;
}