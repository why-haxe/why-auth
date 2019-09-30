package why.auth.plugins.tink.http;

#if !tink_http
	#error 'Plugin tink.http.DelegateProcessors requires the tink_http library'
#end

import why.Delegate;
import tink.http.Client;
import tink.http.Request;
import tink.http.Header;

using tink.CoreApi;

abstract DelegateProcessors(Processors) to Processors {
	public function new<S, C, P, T>(delegate:Delegate<S, C, P, T>, scheme = 'Bearer') {
		this = {
			before: [req -> {
				switch delegate.status.value {
					case SignedIn(user):
						user.getToken()
							.next(token -> new OutgoingRequest(req.header.concat([new HeaderField(AUTHORIZATION, '$scheme $token')]), req.body));
					case SignedOut:
						Promise.resolve(req);
					case Initializing:
						Promise.reject(new Error('Delegate still initializing'));
					case Errored(e):
						Promise.reject(e);
				}
			}]
		}
	}
}