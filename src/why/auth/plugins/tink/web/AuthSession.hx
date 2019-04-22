package why.auth.plugins.tink.web;

#if !tink_web
	#error 'Plugin tink.web.AuthSession requires the tink_web library'
#end

import tink.http.Request;
import tink.Anon.merge;
import why.auth.CognitoAuth;

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
			None
		);
	}
}

class DirectProvider<User> implements ProviderObject<User> {
	
	var make:String->Promise<Option<User>>;
	var schema:String;
	
	public function new(make, schema = 'Direct') {
		this.make = make;
		this.schema = schema;
	}
	
	public function authenticate(header:IncomingRequestHeader):Promise<Option<User>> {
		return switch header.getAuth() {
			case Success(Others(schema, param)) if(schema == this.schema):
				make(param);
			case _:
				None;
		}
	}
}

class BearerProvider<User> implements ProviderObject<User> {
	
	var make:String->Promise<Option<User>>;
	
	public function new(make) {
		this.make = make;
	}
	
	public function authenticate(header:IncomingRequestHeader):Promise<Option<User>> {
		return switch header.getAuth() {
			case Success(Bearer(token)):
				make(token);
			case _:
				None;
		}
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

class CognitoProvider<User> extends BearerProvider<User> {
	public function new(config) {
		super(token -> new CognitoAuth({
			makeUser: config.makeUser,
			region: config.region,
			poolId: config.poolId,
			clientId: config.clientId,
			idToken: token,
		}).authenticate());
	}
}

class FirebaseProvider<User> extends BearerProvider<User> {
	public function new(config) {
		super(token -> new FirebaseAuth({
			makeUser: config.makeUser,
			projectId: config.projectId,
			idToken: token,
		}).authenticate());
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
