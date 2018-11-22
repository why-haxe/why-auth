package ;

import why.Auth;
import why.auth.TinkWebAuth;

using tink.CoreApi;

class RunTests {

  static function main() {
    travix.Logger.println('it works');
    travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }
  
}

class Session {
  var auth:Auth<AuthUser>;
  
  public function new(header) {
    auth = new TinkWebAuth(header, [
      new DirectProvider(id -> switch Std.parseInt(id) {
        case null: None;
        case id: Some(new AuthUser(id));
      }),
      new CognitoProvider({
        makeUser: profile -> switch profile['custom:lix_userid'] {
          case null | Std.parseInt(_) => null: Promise.lift(new Error(Unauthorized, 'Required attribute missing from the token'));
          case Std.parseInt(_) => id: Promise.lift(Some(new AuthUser(id)));
        },
        region: '',
        poolId: '',
        clientId: '',
      })
    ]); 
  }
    
  public function getUser():Promise<Option<AuthUser>> {
    return auth.authenticate();
  }
}

class AuthUser {
  public function new(id) {}
}