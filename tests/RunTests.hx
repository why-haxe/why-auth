package ;

import why.Auth;
import tink.unit.*;
import tink.testrunner.*;
// import why.auth.TinkWebAuth;
 
using tink.CoreApi;

class RunTests {

  static function main() {
    why.auth.AmplifyDelegate;
    why.auth.FirebaseDelegate;
    Runner.run(TestBatch.make([
      new ProfileTest(),
    ])).handle(Runner.exit);
  }
  
}