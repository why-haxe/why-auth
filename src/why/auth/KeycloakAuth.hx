package why.auth;

import jsonwebtoken.Claims;
import jsonwebtoken.verifier.BasicVerifier;
import why.auth.JwkAuth;

using haxe.io.Path;
using tink.CoreApi;

class KeycloakAuth<User> extends JwkAuth<KeycloakProfile, User>{
	
	public function new(config:KeycloakConfig<User> & TokenInput) {
		final backendUrl = switch config.backendUrl {
			case null: config.frontendUrl;
			case v: v;
		}
		super({
			makeUser: config.makeUser,
			jwkUrl: '${backendUrl.removeTrailingSlashes()}/realms/${config.realm}/protocol/openid-connect/certs',
			token: config.token,
			options: {
				iss: '${config.frontendUrl.removeTrailingSlashes()}/realms/${config.realm}',
				// aud: config.clientId,
				aud: 'account',
			},
		});
	}
	
	
	public static inline function verifyToken<User>(input:VerifyInput & TokenInput):Promise<Claims> {
		final backendUrl = switch input.backendUrl {
			case null: input.frontendUrl;
			case v: v;
		}
		return JwkAuth.verifyToken({
			jwkUrl: '${backendUrl.removeTrailingSlashes()}/realms/${input.realm}/protocol/openid-connect/certs',
			token: input.token,
			options: {
				iss: '${input.frontendUrl.removeTrailingSlashes()}/realms/${input.realm}',
				// aud: config.clientId,
				aud: 'account',
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

typedef KeycloakConfig<User> = VerifyInput & {
	final makeUser:KeycloakProfile->Promise<Option<User>>;
}

private typedef VerifyInput = {
	final frontendUrl:String;
	final ?backendUrl:String;
	final realm:String;
	final clientId:String;
}

private typedef TokenInput = {
	final token:String;
}