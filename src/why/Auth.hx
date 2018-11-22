package why;

using tink.CoreApi;

interface Auth<User> {
	function authenticate():Promise<Option<User>>;
}