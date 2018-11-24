package why.auth.plugins.tink.http;

#if !tink_http
	#error 'Plugin tink.http.DelegatedClient requires the tink_web library'
#end

import why.Delegate;
import tink.http.Client;
import tink.http.Request;
import tink.http.Response;
import tink.http.Header;

using tink.CoreApi;

class DelegatedClient implements ClientObject {
	var client:Client;
	var getToken:Void->Promise<Option<String>>;
	var scheme:String;
	
	public function new<P>(client, delegate:Delegate<P>, scheme = 'Bearer') {
		this.client = client;
		this.scheme = scheme;
		this.getToken = delegate.getToken;
	}
	
	public function request(req:OutgoingRequest):Promise<IncomingResponse> {
		return getToken()
			.next(function(o) return client.request(switch o {
				case Some(token):
					new OutgoingRequest(
						req.header.concat([new HeaderField(AUTHORIZATION, '$scheme $token')]),
						req.body
					);
				case None:
					req;
			}));
	}
}