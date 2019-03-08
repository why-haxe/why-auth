# Why Authentication

Abstraction of various authentication mechanism.

## Interface

`Auth` is a server-side interface that identifies an user from some kind of identification. (e.g. access tokens)
```haxe
interface Auth<User> {
	function authenticate():Promise<Option<User>>;
}
```

`Delegate` is a client side interface that allows user to login/logout and generates authentication tokens
```haxe
interface Delegate<Credentials, Profile> {
	var status(default, null):Observable<Status<Profile>>;
	function getToken():Promise<Option<String>>;
	function signIn(credentials:Credentials):Promise<Profile>;
	function signOut():Promise<Noise>;
}
```


## Implementations

**Auth**
- `CognitoAuth` authenticates users using AWS Cognito ID token
- `FirebaseAuth` authenticates users using Firebase ID token

**Delegate**
- `AmplifyDelegate` an implementation for AWS Amplify
- `DummyDelegate` a dummy implementation that exposes the interface methods in a functional programming approach

## Plugins

- `AuthSession.hx` An implementation for `tink_web`'s `Session` which allows using `why.Auth` implementations as authentication providers.
- `DelegateClient.hx` An implementation for `tink_http`'s `Client` which allows using `why.Delegate` implementations as the provider to generate a `AUTHORIZATION` HTTP header.