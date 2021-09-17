package ;

import why.Auth;
import why.auth.DummyDelegate;
import tink.unit.*;
import tink.testrunner.*;
// import why.auth.TinkWebAuth;
 
using tink.CoreApi;

class RunTests {

  static function main() {
    
    
    final realm = 'example';
    final client = 'web';
    final token = 'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI5Y1hNNkNSTHdJcllwSjhmOVlwUXV5UkltZGk1blozUTN4YU9mWWd6VS13In0.eyJleHAiOjE2MzE0OTc3MzAsImlhdCI6MTYzMTQ5NzQzMCwiYXV0aF90aW1lIjoxNjMxNDk2MDg3LCJqdGkiOiIyYWI1N2ViMC02OTQwLTRmZTUtOWIyMS1hZTI3ZWQ0NzM4YTYiLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODAvYXV0aC9yZWFsbXMvZXhhbXBsZSIsImF1ZCI6IndlYiIsInN1YiI6IjkwM2RiN2M2LTkxYjktNDhkMC04YjlhLTg4ZmQ1YWM0MTI4ZSIsInR5cCI6IklEIiwiYXpwIjoid2ViIiwibm9uY2UiOiJlNzlmNjUyMi0wODlmLTQ2YzktODIzNS1lMzY4MGZmMzA0ODEiLCJzZXNzaW9uX3N0YXRlIjoiZjk5MzMzMTAtMTE1MS00ODA3LTk4YzctODEyNWVjNGU0MWNlIiwiYXRfaGFzaCI6IldBY1dQZ0VjV1NRTzlqbDVZaGhETVEiLCJhY3IiOiIwIiwic2lkIjoiZjk5MzMzMTAtMTE1MS00ODA3LTk4YzctODEyNWVjNGU0MWNlIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInByZWZlcnJlZF91c2VybmFtZSI6ImFkbWluQGRhc2xvb3AuY29tIiwiZW1haWwiOiJhZG1pbkBkYXNsb29wLmNvbSJ9.VpBI6c7oK5VXm6isYh67YV5giq-guqteFWpTbx6LNoUhxoHqLBuYLxC5DcLFmodXFAiMm-YSXGuE9_bUvthzAXIZPeHXYQd_ri56kpwV83Yps2SrUFQhauaBB7Gq8-bP2PXRp6F_gg0RzPfvJNCa8EoSQxmGFvBZmzsKko8yyD8ATx8XCKW_Oxv8B0_kbbuuyg_eShgBVP3gr9YdDsp54sUb4zNFTzERMm5aeL9fc9SKhvnw4Ipqvz0ICLVXXK2PrYGsDX7g2TppaKds7O49SgMCqcIA9o6RC-ScX11YSYs4foLPJ26DmBnRgT2TBJ5OylEX1rVAGD5UjU9PoBySzg';
    
    new why.auth.KeycloakAuth({
      makeUser: user -> Some(user),
      frontendUrl: 'http://localhost:8080/auth',
      realm: 'example',
      clientId: 'web',
      token: token,
    }).authenticate()
    .handle(o -> {
      final user = o.sure().sure();
      trace('aud', user.aud);
      trace('email', user.email);
      trace('email_verified', user.email_verified);
      trace('exp', user.exp);
      trace('iat', user.iat);
      trace('iss', user.iss);
      trace('jti', user.jti);
      trace('nbf', user.nbf);
      trace('preferred_username', user.preferred_username);
      trace('sub', user.sub);
      
      trace('acr', user.acr);
      trace('at_hash', user.at_hash);
      trace('azp', user.azp);
      trace('sid', user.sid);
      trace('nonce', user.nonce);
      
      trace('acr', user['acr']);
      trace('at_hash', user['at_hash']);
      trace('azp', user['azp']);
      trace('sid', user['sid']);
      trace('nonce', user['nonce']);
      
      
      trace(user);
    });
      
    
    // why.auth.AmplifyDelegate;
    // why.auth.FirebaseDelegate;
    // Runner.run(TestBatch.make([
    //   new ProfileTest(),
    // ])).handle(Runner.exit);
  }
  
}