
/*
* Studying Tossim radio model by setting up hidden terminal and exposed terminal scenario.
* @autor Wei Shen, Mittuniversitetet
* @date Feb.17 2010
*/
#include <unistd.h>
#include "SimpleTransceiver.h"
#include <stdlib.h>
#include <stdio.h>
#include <time.h> 
module SimpleTransceiverC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Timer<TMilli> as Timer1;
	
    interface SplitControl as AMControl;
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
    interface LocalTime<TMilli>;
    //interface Graph;
    interface Random;
  }
}
implementation {
	int round;
  message_t packet;
  message_t ts;
  int t = 500;
  uint32_t start_time;
  uint32_t temp_time;
  int temp_order;
  uint32_t end_time;
uint32_t  during_time;
  bool locked;
  uint16_t counter = 0;
  uint16_t nCountACK = 0;
  uint32_t max = 2147483647;
  uint32_t random_time;
  int random_NODE;
  int want =0;
	am_addr_t addr;
  int actuator[4][4] = { { 1,2,4,5}, { 2,3,5,6}, { 4,5,7,8}, { 5,6,8,9}};
  int i = 0;
  int j = 0;
  int count = 0; 
  int order[4] = {};
  int timestamps[4] = {99999999,99999999,99999999,99999999};
  int occupy = 0;// if occupy the resource occupy = 1
	simple_transceiver_t* rcm;
simple_transceiver_t* rcm2;
simple_transceiver_t* rcm3;
simple_transceiver_t* rcm4;
simple_transceiver_t* rcm5;


  event void Boot.booted() {      //1 when tinyos system initiates all of its components, turn on the radio.
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
	if(TOS_NODE_ID == 10 || TOS_NODE_ID == 11|| TOS_NODE_ID == 12|| TOS_NODE_ID == 13)
		//call Timer1.startPeriodic(9000);
		call Timer1.startOneShot(8000);
		
		
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {                 //3. timer is fired, send a message with maxlen payload.(radom data)
    
    if (locked) { // busyd
      return;
    }
    else {
	

	
	if(locked) return;
      	else if (call AMSend.send(AM_BROADCAST_ADDR, &packet, 1) == SUCCESS) {// Broadcast doesn't need ACK.
	    //dbg("SimpleTransceiverC", "SimpleTransceiverC: packet sent.\n", counter);	
            start_time = call LocalTime.get();
		dbg("SimpleTransceiverC","send at %d\n",start_time);
	    locked = TRUE;
      }
	  //else send failed
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {   //4. when a message is received, come to here
   
   	
	
	//addr = call AMPacket.source(bufPtr);
	if(len==1){
		
		want = 1;
		dbg("SimpleTransceiverC", "I'm activated \n");
		
		//radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&ts, sizeof(radio_count_msg_t));
		//simple_transceiver_t rcm;
		 rcm = (simple_transceiver_t*)(call Packet.getPayload(&ts, sizeof (simple_transceiver_t*)));
		
		rcm->timestamp = call LocalTime.get() + ((float)call Random.rand32()/max * 50000);
		timestamps[0] = rcm->timestamp;
		order[0] = TOS_NODE_ID ;
		//dbg("SimpleTransceiverC", "I'm %d $$$$$$$$ my t[0] is %d\n",TOS_NODE_ID, timestamps[0]);
		//dbg("SimpleTransceiverC", "random is %f\n", );
		if (call AMSend.send(AM_BROADCAST_ADDR, &ts, sizeof(simple_transceiver_t)) == SUCCESS) {
		
			locked = TRUE;
		}	
	}
	
    	else if (len == sizeof(simple_transceiver_t)) {
			
		if(want == 0)
		{
			dbg("SimpleTransceiverC", "get from %d and I don't want it\n",  call AMPacket.source(bufPtr));
		}
		else if(want == 1)
		{	count ++;
			dbg("SimpleTransceiverC", "get from %d and I  want it\n",  call AMPacket.source(bufPtr));
			 rcm2 = (simple_transceiver_t*)payload;
     	       	        start_time = rcm2->timestamp;//received timestamp;
			timestamps[count]=start_time;
			order[count] = call AMPacket.source(bufPtr);
			for( j = count; j>0; j--){
				if(timestamps[j] < timestamps[j-1])
				{       
					temp_time =  timestamps[j-1];
					 timestamps[j-1] =  timestamps[j];
					 timestamps[j] = temp_time;
					temp_order =  order[j-1];
					 order[j-1] =  order[j];
					 order[j] = temp_order;
					
				}

				else if(timestamps[j] == timestamps[j-1]){
						if (order[j] < order[j-1]){
							temp_time =  timestamps[j-1];
					 		timestamps[j-1] =  timestamps[j];
					 		timestamps[j] = temp_time;
							temp_order =  order[j-1];
					 		order[j-1] =  order[j];
					 		order[j] = temp_order;
						}			
				}
			
			}

/*			
			for( j = count; j>0; j--){
				if(timestamps[j] < timestamps[j-1])
				{
					temp_time =  timestamps[j-1];
					 timestamps[j-1] =  timestamps[j];
					 timestamps[j] = temp_time;
					temp_order =  order[j-1];
					 order[j-1] =  order[j];
					 order[j] = temp_order;
					
				}			

			}
*/
/*
			for ( j = 0; j<3; j++ )
			{
				if ( start_time < timestamps[j]) 
				{
					for ( i = 2-j; i>=0; i--)
					{
						timestamps[i+1] = timestamps[i];
						order[i+1] = order[i];
					}	
					timestamps[j] = start_time;
					order[j] =  call AMPacket.source(bufPtr);	
				}
			}
*/
			
				//dbg("SimpleTransceiverC", " %d>%d>%d>%d \n",order[0],order[1],order[2],order[3]);
			
			//dbg("SimpleTransceiverC", " \n");

			if ( count ==3 )
			{
				if (order[0] == TOS_NODE_ID) 
					{
					dbg("SimpleTransceiverC", "Node %d is running\n",TOS_NODE_ID);
					//call AMSend.send(order[1], &packet, 4);	
					dbg("SimpleTransceiverC", "Node %d told Node %d to run\n",TOS_NODE_ID,order[1]);
					rcm3 = (simple_transceiver_t*)(call Packet.getPayload(&ts, sizeof (simple_transceiver_t*)));
		
					rcm3->a[0] =order[0];
					rcm3->a[1] =order[1];
					rcm3->a[2] =order[2];
					rcm3->a[3] =order[3];
					rcm3->round =1;
					
					if (call AMSend.send(order[1], &ts, 4)==SUCCESS) {
					
									locked = TRUE;
									}	


					}

				
			}
		  	//dbg("SimpleTransceiverC", "timestamp =  %d\n",  start_time);
			//dbg("SimpleTransceiverC", "receive at =  %d\n",  call LocalTime.get());


		}	
      		
	
		//dbg("SimpleTransceiverC", "i get a count %d\n",  rcm->counter);
		//dbg("SimpleTransceiverC", "get it \n");
		

    
  	}

	else if (len == 4 ) {//No.1 send to No.2,No2 send to No3;
		 rcm4 = (simple_transceiver_t*)payload;
     	       	 round = rcm4->round;//received timestamp;
		if(round <= 3)
		{ temp_order = rcm4->a[round];
		//dbg("SimpleTransceiverC", "round =  %d ||||||||  tem_order = %d\n",  round , temp_order);
		dbg("SimpleTransceiverC", "Node %d is running\n",TOS_NODE_ID);
			if(round <3)
		dbg("SimpleTransceiverC", "Node %d told Node %d to run\n",TOS_NODE_ID,order[round+1]);

	
		rcm5 = (simple_transceiver_t*)(call Packet.getPayload(&ts, sizeof (simple_transceiver_t*)));
		rcm5->round = round+1;
		rcm5->a[0] = rcm4->a[0];
		rcm5->a[1] = rcm4->a[1];
rcm5->a[2] = rcm4->a[2];
rcm5->a[3] = rcm4->a[3];
					if (call AMSend.send(order[round+1], &ts, 4)==SUCCESS) {
					
									locked = TRUE;
									}	


		}
	}

	else{}
return bufPtr;
}

event void Timer1.fired() {
	srand((unsigned)time( NULL ) ); 
   			random_NODE = (rand()%100 + 1);
		//random_NODE = (float)(call Random.rand32())/max * 100000;
			//dbg("SimpleTransceiverC", "randomNOde: %d\n", random_NODE);
		if(random_NODE <25 && TOS_NODE_ID ==10)
			
           		 call MilliTimer.startOneShot(0);
		else if(random_NODE >=25 && random_NODE <50 && TOS_NODE_ID ==11)
				
           		 call MilliTimer.startOneShot(0);
		else if(random_NODE >=50 && random_NODE <75 && TOS_NODE_ID ==12)
				
           		 call MilliTimer.startOneShot(0);
		else if(random_NODE >=75 && TOS_NODE_ID ==13)
			
           		 call MilliTimer.startOneShot(0);
	}




  event void AMSend.sendDone(message_t* bufPtr, error_t error) {  //5. Signaled in response to an accepted send request. bufPtr: send buffer, 
                                                   //and error indicates whether the send was successful, and if not, the cause of the failure. 
   
    
	if(error == SUCCESS) 
	{	



		
		locked = FALSE;
	
	}
  }

}




