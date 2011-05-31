/*
Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
The copyrights embodied in the content of this file are licensed under the BSD (revised) open source license
*/
package com.yahoo.astra.managers {
	/**
		function addItem(id : String,source : Object, property : Object = null , required : Boolean = false , validation : Function = null, validatorExtraParam : Object = null,eventTargetObj : DisplayObject = null,functionValidationPassed : Function = null,functionValidationFailed : Function = null, errorString : String = null) : void;
		function collectData(e : MouseEvent = null) : void;
		function addTrigger(button : DisplayObject, functionDataCollectionSuccess : Function = null, functionDataCollectionFail : Function = null) : void;
		function removeTrigger(button : DisplayObject) : void;