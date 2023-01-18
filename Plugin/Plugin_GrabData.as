#name "TMRL grab data "
#author "tmrl team"
#category "TMRL"


bool send_data_float(Net::Socket@ sock, float val)
{
	if (!sock.Write(val)) {
		// If this fails, the socket might not be open. Something is wrong!
		print("INFO: Disconnected, could not send data.");
		return false;
	}
	return true;
}

void Main()
{
	while(true)
	{
		auto sock_serv = Net::Socket();
		if (!sock_serv.Listen("127.0.0.1", 9000)) {
			print("Could not initiate server socket.");
			return;
		}
		print(Time::Now + " Waiting for incomming connection...");

		while(!sock_serv.CanRead()){
			yield();
		}
		print("Socket can read");
		auto sock = sock_serv.Accept();

		print(Time::Now + " Accepted incomming connection.");

		while (!sock.CanWrite()) {
			yield();
		}
		print("Socket can write");
		print(Time::Now + " Connected!");

		bool cc = true;
		while(cc)
		{
			CTrackMania@ app = cast<CTrackMania>(GetApp());
			CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
			CSmArena@ arena = cast<CSmArena>(playground.Arena);
			auto player = arena.Players[0];
			CSmScriptPlayer@ api = cast<CSmScriptPlayer>(player.ScriptAPI);

			auto race_state = playground.GameTerminals[0].UISequence_Current;
			
			// Sending data
			cc = send_data_float(sock, api.Speed);
			send_data_float(sock, api.Distance);
			if(race_state == SGamePlaygroundUIConfig::EUISequence::Finish) 
			{
				send_data_float(sock, 1.0f);
			}
			else send_data_float(sock, 0.0f);

			yield();  // this statement stops the script until the next frame
		}
		sock.Close();
		sock_serv.Close();
	}
}
