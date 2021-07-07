rollout SpringHelperMotionBaker "Spring Helper Motion Baker" width:280 height:165	
(

--==================================================================================================================================
--			Basic			UI			Rollout
--==================================================================================================================================

	checkbox		CHK_CustFrame		""								pos:[10,10]	width:260	height:15
	
	editText		FrameStart			"Start:    "					pos:[30,35]	width:100	height:15
	editText		FrameEnd				"End:   "						pos:[150,35]	width:95	height:15
		
	button			PreChecker			"Pre-Ckeck"					pos:[20,65]	width:90	height:25
	button			SHMBProc				"Start Baking"				pos:[170,65]	width:90	height:25
	
	groupBox		DNBox					"Message" 					pos:[5,95] 	width:270	height:60
		label		MesLab					""								pos:[10,110]	width:260	height:40

--==================================================================================================================================
--			Setting			and			Variable
--==================================================================================================================================
	
	global		BakeAnimationRange		,	TempV01	,	TempV02
	
--==================================================================================================================================
--			Initialize			Function
--==================================================================================================================================
	
	Fn	StartInitialize		=	
	(
		FrameStart.enabled			=	false
		Frameend.enabled			=	false
		
		CHK_CustFrame.caption	=	"                              Using System Animation Range"	
				
		FrameStart.text				=	""
		Frameend.text				=	""
			
	)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	Fn	EnableCustomFrame		=	
	(
		FrameStart.enabled			=	true
		Frameend.enabled			=	true
		
		CHK_CustFrame.caption	=	"Use Custom Animation Range"	
		
		BakeAnimationRange		=	animationRange
		
		FStart	=	BakeAnimationTimer.start	as	string
		FEnd		=	BakeAnimationTimer.end		as	string
		
		FrameStart.text				=	replace	FStart	FStart.count	1	""
		Frameend.text				=	replace	FEnd		FEnd.count	1	""
			
	)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	
	Fn	FreeTempVariable	=	
	(
		Free	BakeAnimationTimer	;		Free	O_SprOBJ		;	Free	B_SprOBJ	;
	)
	
--==================================================================================================================================
--			Check			Function
--==================================================================================================================================

	Fn	CHK_NoneSelect	=		(		if selection.count == 0	then MesLab.caption = "No Object selected"   )

---------------------------------------------------------------------------------------------------------------------------------------------------------------------		

	Fn	CHK_ClassofOBJ	=
	(
		Local	NOP_OBJName	=	""	;	
		
		if	MesLab.caption == 	""	then
		(
			for	x	in	selection	do
			(
				ClassChecker = classof x
				
				if ClassChecker != Point		then	NOP_OBJName	=	NOP_OBJName	+	x.name	+	" ; "
			)

			if		NOP_OBJName	!=		""	then	MesLab.caption = "Not Point Helper : "	+	 NOP_OBJName	+	"\n"
		)
	)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------		
	
	Fn	CHK_LinkParent		=
	(		
		Local	NLK_OBJName	=	""
		
		if		MesLab.caption == 	""	then	(		for	x	in	selection	do	(		if	x.parent	==	undefined		then	NLK_OBJName	=	NLK_OBJName	+	x.name	+	" ; "		)		)

		if		NLK_OBJName	!=		""	then	MesLab.caption = "No Link Parent : "	+	 NLK_OBJName	+	"\n"
	)
	
---------------------------------------------------------------------------------------------------------------------------------------------------------------------		

	Fn	CHK_SPrCtrl	=
	(
		Local	NSC_OBJName	=	""	,	PosCtrlList	=""	
		
		if	MesLab.caption == 	""	then
		(
			for	x	in	selection	do
			(
				case	of	
				(
						(	classof	x.position.controller	==	SpringPositionController		)	:		()

						(	classof	x.position.controller	==	Position_List						)	:
						(
							PosCtrlList	=	(	for 	i	=	1	to	x.position.controller.count
														where		classof x.position.controller[i].controller	==	SpringPositionController
														collect	classof x.position.controller[i].controller
													)

							if		PosCtrlList.count	==	0	then		NSC_OBJName	=	NSC_OBJName	+	x.name	+	" ; "	
						)

						default:		NSC_OBJName	=	NSC_OBJName	+	x.name	+	" ; "
				)
			)

			if		NSC_OBJName	!=		""	then	MesLab.caption = "No Spring Controller : "	+	 NSC_OBJName	+	"\n"
		)
	)
	
---------------------------------------------------------------------------------------------------------------------------------------------------------------------		
	
	Fn	CHK_FrameValue	=
	(
		Local	CustSTF	,	CustEDF
		if	CHK_CustFrame.checked		==	true	then
		(
			CustSTF	=	FrameStart.text	as	integer
			CustEDF	=	FrameEnd.text	as	integer
			
			case	of
			(
				(	CustSTF	==	undefined		or	CustEDF	==	undefined	)	:	(		MesLab.caption =	 "The input value Must be a Integer."		)
				(	CustSTF	>=	CustEDF														)	:	(		MesLab.caption =	 "Start-Frame value must small then End-Frame."		)
				(	(	CustEDF	-	CustSTF	)	<=	2										)	:	(		MesLab.caption =	 "The Animation Range must over then 3."		)
			)
		)
		
	)
	
---------------------------------------------------------------------------------------------------------------------------------------------------------------------		

	Fn	CHK_CheckClear	=		(		if	MesLab.caption ==	 ""	then	MesLab.caption =	 "All check confirm.")
	
	Fn	CHK_MesClean		=		(		MesLab.caption = ""	)

--==================================================================================================================================
--			Baking			Function
--==================================================================================================================================

	Fn	BakeSpringMotion	=
	(
		Local	O_SprOBJ	=	#()	,	B_SprOBJ	=	#()	;
		Local	SpnObjChild	=	""	,	P_OldName	=	""	,	P_OldNameID		;
		Local	BackupSlidertime	,	AniTimes	,	CustSTF	,	CustEDF	;	
		
		BackupAnimationRange	=	animationRange
		BackupSlidertime			=	slidertime

------	------	------						
		
		if		MesLab.caption ==	 ""	then	
		(
			for	x	in	selection	do	append	O_SprOBJ	x
			
------	------	------				
		
			for	i	=	1	to	O_SprOBJ.count	do
			(
				SpnObjChild	 = 	for	 j	 in 	O_SprOBJ[i].parent.children 	collect	 	j.name	
		
				P_OldNameID		=	undefined

				for	k	=	1	to	SpnObjChild.count	do	
				(	
					P_OldName		=	O_SprOBJ[i].name	+	"_SpMoBk"	
		
					if	SpnObjChild[k]	==	P_OldName		then	P_OldNameID	=	SpnObjChild[k]
				)
	
				if	P_OldNameID		!=		undefined		then	append	B_SprOBJ	(	execute(	"$"	+	P_OldNameID	)	)	else
				(
					pt=point size:(O_SprOBJ[i].size * 1.5)  centermarker:false axistripod:false cross:false box:true drawontop:false wirecolor:green
					pt.transform=O_SprOBJ[i].transform
					pt.parent=O_SprOBJ[i].parent
					pt.name=O_SprOBJ[i].name	+	"_SpMoBk"
	
					pt.position.controller = position_list()
					pt.position.controller[2].controller = position_XYZ()
					pt.position.controller.setactive 2
					listctrl.setname pt.position.controller 1 "Frozen Position"
					listctrl.setname pt.position.controller 2 "Zero Pos XYZ"
					pt.position.controller[1].value += pt.position.controller[2].value
					pt.position.controller[2].value = [0,0,0]
	
					append	B_SprOBJ	pt
				)
			)
		
------	------	------	

			if	CHK_CustFrame.checked		==	true	then
			(
				CustSTF	=	FrameStart.text	as	integer
				CustEDF	=	FrameEnd.text	as	integer			
			
				animationRange	=	interval	CustSTF	CustEDF
			)
		
			AniTimes	=	(	(	animationRange.end	-	animationRange.start	)	as	integer	)	/	ticksperframe		
		
			slidertime	=	animationRange.start
		
------	------	------				
		
			set animate on
	
			for	i	=	1	to	AniTimes	+	1	do
			(
				for	j	=	1	to	O_SprOBJ.count		do	B_SprOBJ[j].pos	=	O_SprOBJ[j].transform.pos
	
				slidertime	=	slidertime	+	1	
			)

			set animate off
				
			if		CHK_CustFrame.checked		==	true		then	animationRange	=	BackupAnimationRange	
				
			slidertime	=	AnimationRange.start
			
		)
	)

--==================================================================================================================================
--			Button			Object			Control
--==================================================================================================================================
		
	On	SpringHelperMotionBaker	open						Do 	(	StartInitialize();		)
	On	SpringHelperMotionBaker	close					Do 	(	FreeTempVariable();		)
	
	On 	CHK_CustFrame				 	changed 	state		Do	(	if		CHK_CustFrame.checked		==	true		then	EnableCustomFrame()		else		StartInitialize()		)

	On	PreChecker						pressed					Do	(	CHK_MesClean();	CHK_NoneSelect();		CHK_ClassofOBJ();		CHK_LinkParent();		CHK_SPrCtrl();		CHK_FrameValue();		CHK_CheckClear();		)

	On	SHMBProc							pressed					Do	(	CHK_MesClean();	CHK_NoneSelect();		CHK_ClassofOBJ();		CHK_LinkParent();		CHK_SPrCtrl();		CHK_FrameValue();		BakeSpringMotion();	)
)

createdialog SpringHelperMotionBaker
