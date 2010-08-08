package com.kaltura.kdpfl.controller
{
	import com.kaltura.config.KalturaConfig;
	import com.kaltura.kdpfl.ApplicationFacade;
	import com.kaltura.kdpfl.model.ConfigProxy;
	import com.kaltura.kdpfl.model.ExternalInterfaceProxy;
	import com.kaltura.kdpfl.model.MediaProxy;
	import com.kaltura.kdpfl.model.ServicesProxy;
	import com.kaltura.kdpfl.model.strings.MessageStrings;
	import com.kaltura.kdpfl.model.type.NotificationType;
	import com.kaltura.kdpfl.model.type.SourceType;
	import com.kaltura.kdpfl.model.type.StreamerType;
	import com.kaltura.kdpfl.model.vo.ConfigVO;
	import com.kaltura.kdpfl.util.URLUtils;
	import com.kaltura.kdpfl.view.RootMediator;
	import com.kaltura.vo.KalturaMediaEntry;
	
	import flash.net.SharedObject;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;

	/**
	 * This class syncronises between flash application parameters and parameters passed
	 * by a loading application, and saved all parameters to the config proxy. 
	 */	
	public class SaveFVCommand extends SimpleCommand
	{
		/**
		 * Set the flashvars into the Config Proxy
		 * @param note
		 * 
		 */		
		override public function execute(note:INotification):void
		{
			var mediaProxy : MediaProxy = facade.retrieveProxy( MediaProxy.NAME ) as MediaProxy;
			
			var config:ConfigProxy = facade.retrieveProxy(ConfigProxy.NAME) as ConfigProxy;
			var flashvars:Object = (config.getData() as ConfigVO).flashvars;
			// these are the main application (may be a loader) parameters (flashvars)
			
			var rm:RootMediator = facade.retrieveMediator(RootMediator.NAME) as RootMediator;
			var prop:String;
			
			/*	ATAR - removed this, it does the same work as the constructor of ConfigProxy
			// go over the flashvars and set them to the flashvars vo
			// read the flashvars from loaderinfo
			var o:Object = rm.root.loaderInfo.parameters; 
			for(prop in o)
				flashvars[prop] = o[prop];
			*/
			
			
			// go over the flashvars that passed from any Flex/Flash Container, set or override as needed.
			// read the flashvars from a main container (an application which loaded kdp)
			var o:Object = rm.root["flashvars"]; 
			for(prop in o)
				flashvars[prop] = o[prop];
			

			//set all the flashvars to the Config VO
			(config.getData() as ConfigVO).flashvars = flashvars;

			// instantiate a the MessageStrings once we have the flashvars object  			
//			new MessageStrings(flashvars);
			MessageStrings.init(flashvars);
			
			if (!flashvars.httpProtocol)
			{
				var url:String = rm.root.loaderInfo.url;
				flashvars.httpProtocol = URLUtils.isHttpURL(url) ? URLUtils.getProtocol(url) : "http";  				
			}
			
			if (flashvars.httpProtocol.indexOf("://") == -1)
				flashvars.httpProtocol += "://";				
			
			//backward compatibility in old wrong syntax
			if(flashvars.referer && !flashvars.referrer ) flashvars.referrer = flashvars.referer;
			
			//set application flashvars to be the global flashvars
			rm.root["flashvars"] = flashvars; 
			
			//create the kaltura client by passing it the configuration object base on the flashvars
			setKalturaClientConfig( flashvars );
			
			//if the flashvars say to disable any call to the ExternalInterface API we will do it here
			var extProxy : ExternalInterfaceProxy = facade.retrieveProxy( ExternalInterfaceProxy.NAME ) as ExternalInterfaceProxy;
			//default will be without ExternalInterface. to turn this thing on we will have to get a specific flashvar
			//enabeling it 
			extProxy.vo.enabled = false;
			if(flashvars.externalInterfaceDisabled == "false" || flashvars.externalInterfaceDisabled == "0")
			{
				if(!flashvars.jsCallBackReadyFunc){
					flashvars.jsCallBackReadyFunc = "jsCallbackReady";
				}
				extProxy.vo.enabled = true;
				extProxy.jsCallBackReadyFunc = flashvars.jsCallBackReadyFunc;
				extProxy.registerKDPCallbacks();
			} 
			
			if(flashvars.fileSystemMode == "true" || flashvars.fileSystemMode == "1" )
			{
				flashvars.fileSystemMode = true;
			}
			else
			{
				flashvars.fileSystemMode = false;
			}
			
			if(flashvars.disableOnScreenClick == "true" || flashvars.disableOnScreenClick == "1")
			{
				flashvars.disableOnScreenClick = true;
			}
			else
			{
				flashvars.disableOnScreenClick = false;
			}
				
			//create a new Media Entry if not exist
			if(!mediaProxy.vo.entry)
				mediaProxy.vo.entry = new KalturaMediaEntry();
					
			//set the entryId
			mediaProxy.vo.entry.id=flashvars.entryId;

			ApplicationFacade.getInstance().debugMode = (flashvars.debugMode == "true") ?  true : false;
			
			if(!flashvars.aboutPlayer)	
				flashvars.aboutPlayer= "About Kaltura's Open Source Video Player";
			
			if(!flashvars.aboutPlayerLink)
				flashvars.aboutPlayerLink= "http://corp.kaltura.com/technology/video_player";
			
				
			if(!flashvars.sourceType)
				flashvars.sourceType = SourceType.ENTRY_ID;
							
			if(!flashvars.streamerType)
				flashvars.streamerType = StreamerType.HTTP;
			
			mediaProxy.vo.deliveryType = flashvars.streamerType;	
			//Retrieval of the Bitrate cookie value.	
			var flavorCookie : SharedObject = SharedObject.getLocal("Kaltura");
			if(flashvars.streamerType == StreamerType.HTTP)
			{
				if(flavorCookie.data.preferedFlavorBR){
					mediaProxy.vo.preferedFlavorBR = flavorCookie.data.preferedFlavorBR;
				}
			}
			else
			{
				mediaProxy.vo.preferedFlavorBR = 0;	
				
			}
		}
		
		
		private function setKalturaClientConfig( flashvars : Object ) : void
		{
			var kalturaConfig : KalturaConfig = new KalturaConfig();
			
			if(flashvars.ks) kalturaConfig.ks = flashvars.ks;
			if(flashvars.partnerId) kalturaConfig.partnerId = flashvars.partnerId;
			if(flashvars.host) kalturaConfig.domain = flashvars.httpProtocol + flashvars.host; //TODO: Check if i need to accept the 0,1,2,3 or it's deprecated
			if(flashvars.srvUrl) kalturaConfig.srvUrl = flashvars.srvUrl; 
			
			kalturaConfig.clientTag = "kdp:" + (facade as ApplicationFacade).kdpVersion; //set the clientTag to the current version on the kdp
			if(flashvars.clientTag) kalturaConfig.clientTag += ","+flashvars.clientTag;//if clientTag passed from flashvars concat it to the clientTag as well
			
			var serviceProxy:ServicesProxy  = facade.retrieveProxy(ServicesProxy.NAME) as ServicesProxy;
			serviceProxy.createClient( kalturaConfig );
		}
		
		
		
	}
}