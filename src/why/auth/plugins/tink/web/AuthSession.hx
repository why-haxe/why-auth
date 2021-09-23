package why.auth.plugins.tink.web;

#if !tink_web
	#error 'Plugin tink.web.AuthSession requires the tink_web library'
#end

import tink.http.Request;
import why.auth.CognitoAuth;
import why.auth.KeycloakAuth;
import why.auth.FirebaseAuth;
import why.auth.Auth0Auth;

using tink.CoreApi;

class AuthSession<User> {
	
	var header:IncomingRequestHeader;
	var providers:Array<Provider<User>>;
	
	public function new(header, providers) {
		this.header = header;
		this.providers = providers;
	}
	
	public function getUser():Promise<Option<User>> {
		return Promise.iterate(
			[for(provider in providers) Promise.lazy(provider.authenticate.bind(header))],
			function(result) return result.map(Some),
			None,
			true // fall through on error
		);
	}
}

class AuthHeaderProvider<User> implements ProviderObject<User> {
	
	var make:Authorization->Promise<Option<User>>;
	
	public function new(make) {
		this.make = make;
	}
	
	public function authenticate(header:IncomingRequestHeader):Promise<Option<User>> {
		return switch header.getAuth() {
			case Success(auth): make(auth);
			case _: None;
		}
	}
}

class BearerProvider<User> extends AuthHeaderProvider<User> {
	public function new(make:String->Promise<Option<User>>) {
		super(function(auth) return switch auth {
			case Bearer(v): make(v);
			case _: None;
		});
	}
}

class CookieProvider<User> implements ProviderObject<User> {
	
	var name:String;
	var make:String->Promise<Option<User>>;
	
	public function new(name, make) {
		this.name = name;
		this.make = make;
	}
	
	public function authenticate(header:IncomingRequestHeader):Promise<Option<User>> {
		return switch header.getCookie(name) {
			case null: None;
			case cookie: make(cookie);
		}
	}
}

class QueryProvider<User> implements ProviderObject<User> {
	
	var name:String;
	var make:String->Promise<Option<User>>;
	
	public function new(name, make) {
		this.name = name;
		this.make = make;
	}
	
	public function authenticate(header:IncomingRequestHeader):Promise<Option<User>> {
		return switch header.url.query.toMap().get(name) {
			case null: None;
			case param: make(param);
		}
	}
}

class TokenProvider<User> implements ProviderObject<User> {
	
	var makeUser:String->Promise<Option<User>>;
	
	public function new(makeUser, ?extractToken) {
		this.makeUser = makeUser;
		if(extractToken != null) this.extractToken = extractToken;
	}
	
	dynamic function extractToken(header:IncomingRequestHeader):Outcome<Option<String>, Error> {
		return switch header.getAuth() {
			case Success(Bearer(token)): Success(Some(token));
			case _: Success(None);
		}
	}
	
	public function authenticate(header:IncomingRequestHeader):Promise<Option<User>> {
		return switch extractToken(header) {
			case Success(Some(token)): makeUser(token);
			case Success(None): None;
			case Failure(e): e;
		}
	}
}

typedef CognitoProviderConfig<User> = CognitoConfig<User> & {
	final ?extractToken:IncomingRequestHeader->Outcome<Option<String>, Error>;
}
class CognitoProvider<User> extends TokenProvider<User> {
	public function new(config:CognitoProviderConfig<User>) {
		super(token -> new CognitoAuth({
			makeUser: config.makeUser,
			region: config.region,
			poolId: config.poolId,
			clientId: config.clientId,
			token: token,
		}).authenticate(), config.extractToken);
	}
}

typedef KeycloakProviderConfig<User> = KeycloakConfig<User> & {
	final ?extractToken:IncomingRequestHeader->Outcome<Option<String>, Error>;
}
class KeycloakProvider<User> extends TokenProvider<User> {
	public function new(config:KeycloakProviderConfig<User>) {
		super(token -> new KeycloakAuth({
			makeUser: config.makeUser,
			frontendUrl: config.frontendUrl,
			backendUrl: config.backendUrl,
			realm: config.realm,
			clientId: config.clientId,
			token: token,
		}).authenticate(), config.extractToken);
	}
}

typedef FirebaseProviderConfig<User> = FirebaseConfig<User> & {
	final ?extractToken:IncomingRequestHeader->Outcome<Option<String>, Error>;
}
class FirebaseProvider<User> extends TokenProvider<User> {
	public function new(config:FirebaseProviderConfig<User>) {
		super(token -> new FirebaseAuth({
			makeUser: config.makeUser,
			projectId: config.projectId,
			token: token,
		}).authenticate(), config.extractToken);
	}
}

typedef Auth0ProviderConfig<User> = {
	var domain(default, null):String;
	var clientId(default, null):String;
	var makeUser(default, null):Auth0Profile->Promise<Option<User>>;
	@:optional var extractToken(default, null):IncomingRequestHeader->Outcome<Option<String>, Error>;
}
class Auth0Provider<User> extends TokenProvider<User> {
	public function new(config:Auth0ProviderConfig<User>) {
		super(token -> new Auth0Auth({
			makeUser: config.makeUser,
			domain: config.domain,
			clientId: config.clientId,
			token: token,
		}).authenticate(), config.extractToken);
	}
}

class SimpleProvider<User> implements ProviderObject<User> {
	var f:IncomingRequestHeader->Promise<Option<User>>;
	public function new(f)
		this.f = f;
	public function authenticate(header:IncomingRequestHeader):Promise<Option<User>>
		return f(header);
}

@:forward
abstract Provider<User>(ProviderObject<User>) from ProviderObject<User> to ProviderObject<User> {
	@:from public static inline function fromFunction<User>(f:IncomingRequestHeader->Promise<Option<User>>):Provider<User>
		return new SimpleProvider(f);
}
interface ProviderObject<User> {
	function authenticate(header:IncomingRequestHeader):Promise<Option<User>>;
}
