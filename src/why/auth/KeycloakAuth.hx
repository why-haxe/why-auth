package why.auth;

import jsonwebtoken.Claims;
import jsonwebtoken.verifier.BasicVerifier;
import why.auth.JwkAuth;

using haxe.io.Path;
using tink.CoreApi;

class KeycloakAuth<User> extends JwkAuth<KeycloakProfile, User>{
	
	public function new(config:KeycloakConfig<User>) {
		final domain = '${config.frontendUrl.removeTrailingSlashes()}/realms/${config.realm}';
		super({
			makeUser: config.makeUser,
			jwkUrl: '$domain/protocol/openid-connect/certs',
			token: config.token,
			options: {
				iss: domain,
				aud: config.clientId,
			},
		});
	}
}

@:forward
abstract KeycloakProfile(KeycloakProfileObj) from KeycloakProfileObj to KeycloakProfileObj {
	@:resolve @:arrayAccess
	public inline function resolve(key:String):String return Reflect.field(this, key);
}

typedef KeycloakProfileObj = {
	> Claims,
	final ?email_verified:Bool;
	final ?preferred_username:String;
	final ?email:String;
	
	// final ?acr:Int;
	// final ?at_hash:String;
	// final ?azp:String;
	// final ?sid:String;
	// final ?nonce:String;
}

typedef KeycloakConfig<User> = {
	> VerifyInput,
	final makeUser:KeycloakProfile->Promise<Option<User>>;
}

private typedef VerifyInput = {
	final frontendUrl:String;
	final realm:String;
	final clientId:String;
	final token:String;
}