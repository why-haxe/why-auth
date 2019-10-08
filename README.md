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
interface Delegate<SignUpInfo, Credentials, Profile, ProfilePatch> {
	var status(default, null):Observable<Status<User<Profile, ProfilePatch>>>;
	function signUp(info:SignUpInfo):Promise<Noise>;
	function signIn(credentials:Credentials):Promise<Noise>;
	function signOut():Promise<Noise>;
	
	function forgetPassword(id:String):Promise<Noise>;
	function resetPassword(id:String, code:String, password:String):Promise<Noise>;
	function confirmSignUp(id:String, code:String):Promise<Noise>;
}

interface User<Profile, ProfilePatch> {
	var profile(default, null):Observable<Profile>;
	function getToken():Promise<String>;
	function updateProfile(patch:ProfilePatch):Promise<Noise>;
	function changePassword(oldPassword:String, newPassword:String):Promise<Noise>;
}

enum Status<Profile> {
	Initializing;
	SignedOut;
	SignedIn(profile:Profile);
	Errored(e:Error);
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