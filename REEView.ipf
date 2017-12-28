#pragma rtGlobals=1
StrConstant RVVersion = "1.2"

Menu "REEView"
	"Live", RVStartLiveREE()
	"Average", RVAverageREE()
	"All", RVAllREE()
	"-"
	"Elements", RVShowElements()
	"Normalization", RVShowNorms()
	"Reinitialize", RVInit()
	"-"
	"About", RVShowAbout()
End

// Initialize everything
Function RVInit()
	Print "[REEview] Initializing..."
	NewDataFolder/O/S root:Packages:REEView	
	
	// Check for Iolite + trace element DRS
	SVAR ioliteDRS = root:Packages:iolite:output:S_currentDRS
	If (cmpstr(ioliteDRS, "Trace_Elements") != 0 )
		Print "[REEview] Iolite Trace_Elements DRS is not active?  This might be bad."
	EndIf
	
	// Make a wave to store which elements are selected for display
	Make/O/B/N=50 activeElements=0
	Variable/G nPPMOutputs
	Variable/G nOutputs
	Variable/G nREE = 14
	
	// Get list of ppm outputs
	SVAR outputChannels = root:Packages:iolite:output:ListOfOutputChannels
	String/G ppmOutputs = ""
	
	nOutputs = ItemsInList(outputChannels)

	// Make a wave for elements
	Make/O/N=(nREE)/T reeElements
	reeElements = {"La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu"}
	
	// Make a wave for ionic radii (not sure what the units are here, or whether it is correct?)
	Make/O/N=(nREE) reeIonicRadii
	reeIonicRadii = {1.032, 1.01, 0.99, 0.983, 0.97, 0.947, 0.938, 0.923, 0.912, 0.901, 0.89, 0.88, 0.868, 0.861}
	
	// Make a wave for inverse ionic radii
	Make/O/N=(nREE) reeInvIonicRadii
	reeInvIonicRadii = 1/reeIonicRadii	
	
	// Make a wave for ree atomic numbers
	Make/O/N=(nREE) reeAtomicNumbers
	reeAtomicNumbers = {57, 58, 59, 60, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71 }

	String/G locationsList = "reeIonicRadii;reeInvIonicRadii;reeAtomicNumbers;"
	
	// Make standard waves: additional standards should be defined here!
	Make/O/N=(nREE)/T stdCI_AG89, stdCI_MS89, stdCI_MS95, stdMUQ_K05, stdMUQ_MK10, stdMORB_AM10, stdNMORB_SM89, stdNMORB_H88, stdEMORB_SM89, stdOIB_SM89, stdSudbury, stdLAOnaping, stdUCC, stdMCC, stdLCC, stdBCC
	stdCI_AG89 = {"0.2347", "0.6032", "0.0891", "0.4524", "0.1471", "0.0560", "0.1966", "0.0363", "0.2427", "0.0556", "0.1589", "0.0242", "0.1625", "0.0243"}
	stdCI_MS89 = {"0.237", "0.612", "0.095", "0.467", "0.153", "0.058", "0.2055", "0.0374", "0.254", "0.0566", "0.1655", "0.0255", "0.170", "0.0254"}
	stdCI_MS95 = {"0.237", "0.613", "0.0928", "0.457", "0.148", "0.0563", "0.199", "0.0361", "0.246", "0.0546", "0.160", "0.0247", "0.161", "0.0246"}
	stdMUQ_K05 = {"32.51", "71.09", "8.46", "32.91", "6.88", "1.57", "0.636", "0.99", "5.89", "1.22", "3.37", "0.51", "3.25", "0.49"}
	stdMUQ_MK10 = {"34.794", "72.19", "8.581", "32.006", "6.277", "1.121", "5.364", "0.798", "4.543", "0.912", "2.533", "0.388", "2.533", "0.377"}
	stdMORB_AM10 = {"3.77", "11.5", "1.74", "9.8", "3.25", "1.22", "4.4", "0.738", "5.11", "1.05", "3.15", "0.453", "3.0", "0.454"}
	stdNMORB_SM89 = { "2.5", "7.5", "1.32", "7.3", "2.63", "1.02", "3.68", "0.67", "4.55", "1.01", "2.97", "0.456", "3.05", "0.455" }
	stdNMORB_H88 = { "3.895", "12.001", "2.074", "11.179", "3.752", "1.335", "5.077", "0.885", "6.304", "1.342", "4.143", "0.621", "3.9", "0.589" }
	stdEMORB_SM89 = {"6.3", "15.0", "2.05", "9.0", "2.6", "0.91", "2.97", "0.53", "3.55", "0.79", "2.31", "0.356", "2.37", "0.354"}
	stdOIB_SM89 = { "37", "80", "9.7", "38.5", "10", "3", "7.62", "1.05", "5.6", "1.06", "2.62", "0.35", "2.16", "0.3" }
	stdUCC = {"31", "63", "7.1", "27", "4.7", "1", "4", "0.7", "3.9", "0.83", "2.3", "0.3", "2", "0.31"}
	stdMCC = {"24", "53", "5.8", "25", "4.6", "1.4", "4", "0.7", "3.8", "0.82", "2.3", "0.32", "2.2", "0.4"}
	stdLCC = {"8", "20", "2.4", "11", "2.8", "1.1", "3.1", "0.48", "3.1", "0.68", "1.9", "0.24", "1.5", "0.25"}
	stdBCC = {"20", "43", "4.9", "20", "3.9", "1.1", "3.7", "0.6", "3.6", "0.77", "2.1", "0.28", "1.9", "0.3"}
	Variable/G nNorms = 14
	
	// Make normalization matrix
	Make/O/N=(nNorms+1, nREE + 1)/T normMatrix
	normMatrix[0][1,nREE] = reeElements[q-1]
	normMatrix[1][1,nREE] = stdCI_AG89[q-1]
	normMatrix[2][1,nREE] = stdCI_MS89[q-1]
	normMatrix[3][1,nREE] = stdCI_MS95[q-1]
	normMatrix[4][1,nREE] = stdMUQ_K05[q-1]
	normMatrix[5][1,nREE] = stdMUQ_MK10[q-1]
	normMatrix[6][1,nREE] = stdMORB_AM10[q-1]
	normMatrix[7][1,nREE] = stdNMORB_SM89[q-1]
	normMatrix[8][1,nREE] = stdNMORB_H88[q-1]
	normMatrix[9][1,nREE] = stdEMORB_SM89[q-1]
	normMatrix[10][1,nREE] = stdOIB_SM89[q-1]
	normMatrix[11][1,nREE] = stdUCC[q-1]
	normMatrix[12][1,nREE] = stdMCC[q-1]
	normMatrix[13][1,nREE] = stdLCC[q-1]
	normMatrix[14][1,nREE] = stdBCC[q-1]
	normMatrix[1][0] = "CI_AG89"
	normMatrix[2][0] = "CI_MS89"
	normMatrix[3][0] = "CI_MS95"
	normMatrix[4][0] = "MUQ_K05"
	normMatrix[5][0] = "MUQ_MK10"
	normMatrix[6][0] = "MORB_AM10"
	normMatrix[7][0] = "NMORB_SM89"
	normMatrix[8][0] = "NMORB_H88"
	normMatrix[9][0] = "EMORB_SM89"
	normMatrix[10][0] = "OIB_SM89"
	normMatrix[11][0] = "UCC"
	normMatrix[12][0] = "MCC"
	normMatrix[13][0] = "LCC"
	normMatrix[14][0] = "BCC"
	String/G normList = "CI_AG89;CI_MS89;CI_MS95;MUQ_K05;MUQ_MK10;MORB_AM10;NMORB_SM89;NMORB_H88;EMORB_SM89;OIB_SM89;UCC;MCC;LCC;BCC;"
	
	// Set dim labels for normMatrix for easy access
	SetDimLabel 0, 0, Element, normMatrix
	SetDimLabel 0, 1, CI_AG89, normMatrix
	SetDimLabel 0, 2, CI_MS89, normMatrix
	SetDimLabel 0, 3, CI_MS95, normMatrix
	SetDimLabel 0, 4, MUQ_K05, normMatrix
	SetDimLabel 0, 5, MUQ_MK10, normMatrix
	SetDimLabel 0, 6, MORB_AM10, normMatrix
	SetDimLabel 0, 7, NMORB_SM89, normMatrix
	SetDimLabel 0, 8, NMORB_H88, normMatrix
	SetDimLabel 0, 9, EMORB_SM89, normMatrix
	SetDimLabel 0, 10, OIB_SM89, normMatrix
	SetDimLabel 0, 11, UCC, normMatrix
	SetDimLabel 0, 12, MCC, normMatrix
	SetDimLabel 0, 13, LCC, normMatrix
	SetDimLabel 0, 14, BCC, normMatrix

	SetDimLabel 1, 0, Standard, normMatrix
	SetDimLabel 1, 1, La, normMatrix
	SetDimLabel 1, 2, Ce, normMatrix
	SetDimLabel 1, 3, Pr, normMatrix
	SetDimLabel 1, 4, Nd, normMatrix
	SetDimLabel 1, 5, Sm, normMatrix
	SetDimLabel 1, 6, Eu, normMatrix
	SetDimLabel 1, 7, Gd, normMatrix
	SetDimLabel 1, 8, Tb, normMatrix
	SetDimLabel 1, 9, Dy, normMatrix
	SetDimLabel 1, 10, Ho, normMatrix
	SetDimLabel 1, 11, Er, normMatrix
	SetDimLabel 1, 12, Tm, normMatrix
	SetDimLabel 1, 13, Yb, normMatrix
	SetDimLabel 1, 14, Lu, normMatrix
	
	String/G activeNorm = "CI_AG89"
	String/G dataLocator = "reeAtomicNumbers"
	
	// Determine which of the ppm outputs are REEs
	Variable i = 0
	For (i = 0; i < nOutputs; i = i + 1)
		String curOutput = StringFromList(i, outputChannels)
		
		String curOutputStripped = curOutput[0,1]
		
		If (strsearch(curOutputStripped,"_",0) != -1)
			curOutputStripped = curOutputStripped[0]
			Continue
		EndIf
		
		FindValue/TEXT=curOutputStripped/TXOP=1 reeElements
		If ( strsearch(curOutput, "ppm", 0) != -1 && V_value != -1)
			ppmOutputs = ppmOutputs + curOutput + ";"
		EndIf
	EndFor	
		
	nPPMOutputs = ItemsInList(ppmOutputs)
	
	Variable/G reeInitialized
	if (nPPMOutputs == 0)
		Print "[REEView] Have you crunched the data? Can't find ppm outputs"
		reeInitialized = 0
	Else	
		// Default to all REEs being active
		For (i = 0; i < nPPMOutputs; i = i + 1)
			FindValue/TEXT=StringFromList(i, ppmOutputs)[0,1] reeElements
			If ( V_value != -1)
				activeElements[i] = 1
			EndIf
		EndFor
		
		reeInitialized = 1
	EndIf
	
End

// Initialize if not done already
Function RVEnsureInit()
	NVAR reeInitialized
	
	If (reeInitialized != 1 || !exists("reeInitialized"))
		RVInit()
	EndIf
End

// Get normalization data for a particular element for a particular normalizer
Function RVGetNormValue(normStr, elStr)
	String normStr, elStr
	
	RVEnsureInit()
	
	Wave/T normMatrix = $"normMatrix"
	
	String valStr = normMatrix[%$normStr][%$elStr]
	
	Return str2num(valStr)
End

//////////////////////////
// Construct the elements panel
Function RVElementsPanel() : Panel
	PauseUpdate; Silent 1
	
	RVEnsureInit()
	
	NewPanel/K=1/N=RVElements/W=(200,200,400,480) as "Elements"
	ModifyPanel/W=RVElements fixedSize=1
	SVAR ppmOutputs
	NVAR nPPMOutputs
	
	Wave activeElements = $"activeElements"
	
	Redimension/N=(nPPMOutputs) activeElements
	Make/O/N=(nPPMOutputs)/T availableElements
	
	// Create wave of available outputs from ppmOutputs string list
	Variable i
	For(i = 0; i < nPPMOutputs; i = i + 1)
		availableElements[i] = StringFromList(i, ppmOutputs)
	EndFor
	
	// Show a list box to select the active elements
	ListBox listAvElements listWave=availableElements, size={198,250}, mode=4, selWave=activeElements

	SVAR locationsList
	SVAR dataLocator
	PopupMenu dataLocatorPopup mode=1, title="Locations: ", value=#"locationsList", popvalue=dataLocator, proc=dataLocatorPopupProc
End

// Update the dataLocator according to selection
Function dataLocatorPopupProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	SVAR dataLocator
	
	If ( PU_Struct.eventCode == 2 )
		dataLocator= PU_Struct.popStr
	EndIf
End

// Show the elements window
Function RVShowElements()
	DoWindow/F RVElementsPanel
	Execute "RVElementsPanel()"
End

// Normalization panel
Function RVNormsPanel() : Panel
	PauseUpdate; Silent 1
	
	RVEnsureInit()
	
	NewPanel/K=1/N=RVNorms/W=(200,200,995,500) as "Normalization"
	ModifyPanel/W=RVNorms fixedSize=1
	
	Wave normMatrix = $"normMatrix"
	SVAR normList
	SVAR activeNorm
	
	PopupMenu actNormPopup mode=1, title="Active Normalization: ", value=#"normList",popvalue=activeNorm, proc=normPopupProc
	
	Edit/N=NormTable/HOST=RVNorms/W=(0,25,795,275) normMatrix
	ModifyTable/W=RVNorms#NormTable showParts=97, width=50, entryMode =1
	ModifyTable/W=RVNorms#NormTable width[1]=75
	
	DrawText 10, 295, "Note: You must edit REEView.ipf to change the normalization values permanently!"
End

// Update the normalization according to selection
Function normPopupProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	SVAR activeNorm
	If (PU_Struct.eventCode == 2)
		activeNorm = PU_Struct.popStr
	EndIf
End

// Show the normalization window
Function RVShowNorms()
	DoWindow/F RVNormsPanel
	Execute "RVNormsPanel()"
End

// REEView about panel
Window RVAboutPanel() : Panel
	PauseUpdate; Silent 1
	
	String IgorInfoStr=IgorInfo(0)
	Variable scr0 = strsearch(IgorInfoStr,"RECT",0)
	Variable scr1 = strsearch(IgorInfoStr,",",scr0+9)
	Variable scr2 = strlen(IgorInfoStr)-2
	Variable screenWidth = str2num(IgorInfoStr[scr0+9,scr1-1])
	Variable screenHeight = str2num(IgorInfoStr[scr1+1,scr2])
	
	Variable panelWidth = 300
	Variable panelHeight = 80
	
	NewPanel/W=(screenWidth/2-panelWidth/2,screenHeight/2-panelHeight/2,screenWidth/2+panelWidth/2,screenHeight/2+panelHeight/2)/K=1 as "About"
	ModifyPanel fixedSize=1
	
	SetDrawEnv fsize= 18;DelayUpdate
	DrawText 30,30,"REEView"
	DrawText 30,50,"Version: " + RVVersion
	DrawText 30,70,"Created by: Joe Petrus"
End

// Show the about window
Function RVShowAbout()
	DoWindow/F RVAboutPanel
	Execute "RVAboutPanel()"
End

// Get normalization data from matrix and store in the specified wave
Function RVSetNormWave(normWaveStr)
	String normWaveStr
	
	RVEnsureInit()
	
	SVAR activeNorm
	NVAR nREE
	
	Wave/T normMatrix = $"normMatrix"
	Wave normWave = $normWaveStr
	
	// Copy data from normMatrix to normWave for the active normalization
	Variable i
	For (i = 0; i < nREE; i = i + 1)
		normWave[i] = str2num(normMatrix[%$activeNorm][i+1])
	EndFor
End

// Setup live REE plot and start background process to update data
Function RVStartLiveREE()

	RVEnsureInit()
	
	// Get some global parameters
	Variable/G PreviousLiveIntNum = -1
	Variable/G PreviousLiveStartIndex = 0
	Variable/G PreviousLiveStopIndex = 0
	String/G PreviousLocator = ""
	SVAR ppmOutputs
	NVAR nPPMOutputs
	NVAR nREE
	
	// Construct panel (that hosts the graph)
	NewPanel/FLT/N=REEPanel/K=1/W=(200, 200, 700, 600 )
	SetActiveSubwindow _endfloat_
	ModifyPanel/W=REEPanel fixedSize=0
	
	// Make waves used for plot
	Make/O/N=(nREE) rvNormData, rvData, rvNorm, rvLabels, rvMask
	
	// Set the normalization data
	RVSetNormWave("rvNorm")

	SVAR dataLocator
	
	PreviousLocator = dataLocator

	// Set the locations and label data
	Wave reeLocations = $dataLocator
	Wave reeLabels = $"reeElements"
	
	// Display plot in panel
	Display/N=Live_REE/HOST=REEPanel/FG=(FL,FT,FR,FB) rvNormData vs reeLocations

	// Set background process and start it
	SetBackground RVUpdateLiveREE()
	CtrlBackground dialogsOK=1,noBurst=1,period=(10), start
	
	// Set the window hook function
	SetWindow REEPanel, hook(REEUpdateHook)=RVLiveREEHook
	
	// Modify graph characteristics
	ModifyGraph userticks(bottom)={reeLocations, reeLabels}	
	ModifyGraph/W=REEPanel#Live_REE log(left)=1
	ModifyGraph/W=REEPanel#Live_REE mirror=2,standoff=0;DelayUpdate
	Label/W=REEPanel#Live_REE left "Integration / Normalization";DelayUpdate
	ModifyGraph/W=REEPanel#Live_REE mode=4,marker=19	
	ModifyGraph/W=REEPanel#Live_REE width=500, height=400
	ModifyGraph/W=REEPanel#Live_REE gFont="Helvetica",gfSize=14
	ModifyGraph/W=REEPanel#Live_REE grid(left)=2
	SetAxis/W=REEPanel#Live_REE bottom WaveMin(reeLocations), WaveMax(reeLocations)
	SetAxis/W=REEPanel#Live_REE left 10^floor(log(WaveMin(rvNormData))), 10^ceil(log(WaveMax(rvNormData)))	

	// Return focus to the other window
	SetActiveSubWindow _endfloat_
End

// Hook to change window behavior
Function RVLiveREEHook(s)
	STRUCT WMWinHookStruct &s
	
	Switch(s.eventCode)
		Case 2: // Window closed: stop background process
			CtrlBackground stop
			Break
	EndSwitch
	
	SetActiveSubwindow _endfloat_
	Return 0
End


//Function RVLiveREEResize()
//	GetWindow REEPanel wsize
//	Variable reewidth = V_right-V_left-105
//	Variable reeheight = V_bottom-V_top -65
//	ModifyGraph/W=REEPanel#Live_REE width=reewidth, height=reeheight
//End

//////////////////////////////
// Updates data used for live REE plot
Function RVUpdateLiveREE()

	RVEnsureInit()

	// Get list of usable outputs + number of REEs
	SVAR ppmOutputs
	NVAR nREE
	
	// Get waves used for plotting
	Wave rvData = $"rvData", rvNorm = $"rvNorm", rvNormData = $"rvNormData", rvMask = $"rvMask"
	
	// Set the normalization data
	RVSetNormWave("rvNorm")

	SVAR dataLocator
	SVAR PreviousLocator
	
	// Check if locator has changed:
	If (cmpstr(dataLocator, PreviousLocator) != 0)

		// Set the locations and label data
		Wave reeLocations = $dataLocator
		Wave reeLabels = $"reeElements"
		
		RemoveFromGraph/W=REEPanel#Live_REE rvNormData
		AppendToGraph/W=REEPanel#Live_REE rvNormData vs reeLocations

		ModifyGraph/W=REEPanel#Live_REE userticks(bottom)={reeLocations, reeLabels}	
		ModifyGraph/W=REEPanel#Live_REE log(left)=1
		ModifyGraph/W=REEPanel#Live_REE mirror=2,standoff=0;DelayUpdate
		Label/W=REEPanel#Live_REE left "Integration / Normalization";DelayUpdate
		Label/W=REEPanel#Live_REE bottom "Element"	
		ModifyGraph/W=REEPanel#Live_REE mode=4,marker=19	
		ModifyGraph/W=REEPanel#Live_REE width=500, height=400
		ModifyGraph/W=REEPanel#Live_REE gFont="Helvetica",gfSize=14
		ModifyGraph/W=REEPanel#Live_REE grid(left)=2
		SetAxis/W=REEPanel#Live_REE bottom WaveMin(reeLocations), WaveMax(reeLocations)
		SetAxis/W=REEPanel#Live_REE left 10^floor(log(WaveMin(rvNormData))), 10^ceil(log(WaveMax(rvNormData)))			
		//RVLiveREEResize()
	EndIf

	PreviousLocator = dataLocator	
	
	// Get some stuff from Iolite
	Wave index_time = $ioliteDFpath("CurrentDRS", "Index_Time")
	String MatrixName = RVGetMatrixName()
	Wave aim = $ioliteDFpath("integration", "m_" + MatrixName)
	
	// Get the required global variables:
	NVAR previousIntegrationNum = root:Packages:REEView:PreviousLiveIntNum
	Variable activeIntNum = RVGetActiveIntNum()
	NVAR prevStartIndex = root:Packages:REEView:PreviousLiveStartIndex
	NVAR prevStopIndex = root:Packages:REEView:PreviousLiveStopIndex

	// Determine the current integration's range:	
	Variable startTime = (aim[activeIntNum][0][0] - aim[activeIntNum][0][1])
	Variable stopTime= (aim[activeIntNum][0][0] + aim[activeIntNum][0][1])
	Variable startIndex = ForBinarySearch(index_time, startTime) + 1
	Variable stopIndex = ForBinarySearch(index_time, stopTime)

	// .. and check if it has changed:
//	If (startIndex == prevStartIndex && stopIndex == prevStopIndex)
		// If range hasn't changed - exit, but keep background process running
//		Return 0
//	Endif

	// Update the start and stop indices:
	prevStartIndex = startIndex
	prevStopIndex = stopIndex
	
	// Create a mask for elements that aren't being used:
	Wave activeElements = $"activeElements"

	Variable i 
	For (i = 0; i < nREE; i = i + 1)
		If (activeElements[i] != 1)
			rvMask[i] = Nan
		Else
			rvMask[i] = 1
		EndIf
	EndFor
	
	// Update the data:
	For (i = 0; i < nREE; i = i + 1)
		String curCh = StringFromList(i, ppmOutputs)
		
		rvData[i] = RVGetIntegrationFromIolite(curCh, MatrixName, activeIntNum, "resultWave")
		rvNormData[i] = rvMask[i]*rvData[i]/rvNorm[i]
	EndFor

	SetAxis/W=REEPanel#Live_REE left 10^floor(log(WaveMin(rvNormData))), 10^ceil(log(WaveMax(rvNormData)))	

	previousIntegrationNum = activeIntNum
	
	// Return 0 to keep the background process running!
	Return 0
End

Function RVGetIntegrationFromIolite(ChannelStr, IntStr, IntNum, ResultStr)
	String ChannelStr, IntStr, ResultStr
	Variable IntNum
	
	Wave aim= $ioliteDFpath("Integration", "m_" + IntStr)
	Wave ResultWave = $MakeioliteWave("CurrentDRS", ResultStr, n=2)	
	
	RecalculateIntegrations("m_" + IntStr, ChannelStr, RowNumber=IntNum)
	
	ResultWave[0] = aim[IntNum][%$ChannelStr][2]
	ResultWave[1] = aim[IntNum][%$ChannelStr][3]
	
	Return ResultWave[0]
End

Function RVAverageREE()

	RVEnsureInit()
	
	NVAR nREE
	
	//Wave rvData = $"rvData", rvNorm = $"rvNorm", rvNormData = $"rvNormData", rvMask = $"rvMask"
	SVAR ppmOutputs
	Make/O/N=(nREE) rvAvgData, rvAvgNormData, rvData, rvNorm, rvNormData, rvMask
		
	Wave activeElements = $"activeElements"
	
	Variable i
	For (i = 0; i < nREE; i = i + 1)
		If (activeElements[i] !=1)
			rvMask[i] = Nan
		Else
			rvMask[i] = 1
		EndIf
	EndFor
	
	String usefulIntegrations = RVGetListOfUsefulIntegrations()
	String MatrixName
	
	Prompt MatrixName, "Which Integration Type? ", popup, usefulIntegrations
	DoPrompt/HELP="" "REEView", MatrixName
	If (V_Flag)
		Return -1
	EndIf
		
	// Get some stuff from Iolite
	Wave index_time = $ioliteDFpath("CurrentDRS", "Index_Time")
	//SVAR MatrixName = root:Packages:iolite:traces:MatrixName
	Wave aim = $ioliteDFpath("integration", "m_" + MatrixName)	
	Variable NoOfIntegrations = DimSize(aim,0) 

	// Set the normalization data
	RVSetNormWave("rvNorm")

	If (FindListItem("Avg_REE", WinList("*", ";", "")) == -1)
		Display/N=Avg_REE/K=1
	EndIf

	For (i = 0; i < nREE; i = i + 1)
	
		String curCh = StringFromList(i, ppmOutputs)
		rvAvgData[i] = 0
		Variable j
		For (j = 1; j < NoOfIntegrations; j = j + 1)
			// Determine the current integration's range:	
			Variable startTime = (aim[j][0][0] - aim[j][0][1])
			Variable stopTime= (aim[j][0][0] + aim[j][0][1])
			Variable startIndex = ForBinarySearch(index_time, startTime) + 1
			Variable stopIndex = ForBinarySearch(index_time, stopTime)
			
//			rvAvgData[i] = rvAvgData[i] + IntegrateChannel(curCh, startTime, stopTime, "resultWave")
			rvAvgData[i] = rvAvgData[i] + RVGetIntegrationFromIolite(curCh, MatrixName, j, "resultWave")
		EndFor
		rvAvgData = rvAvgData/(NoOfIntegrations-1)
		
		//Print rvAvgData[i]
		
		//Print rvNorm[i]
		rvAvgNormData[i] = rvMask[i]*rvAvgData[i]/rvNorm[i]
	EndFor


	SVAR dataLocator
	//PreviousLocator = dataLocator

	// Set the locations and label data
	Wave reeLocations = $dataLocator
	Wave reeLabels = $"reeElements"
	
	// Display plot in panel
	AppendToGraph/W=Avg_REE rvAvgNormData vs reeLocations

	// Modify graph characteristics
	ModifyGraph userticks(bottom)={reeLocations, reeLabels}	
	ModifyGraph/W=Avg_REE log(left)=1
	ModifyGraph/W=Avg_REE mirror=2,standoff=0;DelayUpdate
	Label/W=Avg_REE left "Integration / Normalization";DelayUpdate
//	Label/W=Avg_REE bottom ""	
	ModifyGraph/W=Avg_REE mode=4,marker=19	
	ModifyGraph/W=Avg_REE width=500, height=400
	ModifyGraph/W=Avg_REE gFont="Helvetica",gfSize=14
	ModifyGraph/W=Avg_REE grid(left)=2
	SetAxis/W=Avg_REE bottom WaveMin(reeLocations), WaveMax(reeLocations)
	SetAxis/W=Avg_REE left 10^floor(log(WaveMin(rvAvgNormData))), 10^ceil(log(WaveMax(rvAvgNormData)))
	

End

Function RVAllREE()

	RVEnsureInit()
	
	NVAR nREE
	
	//Wave rvData = $"rvData", rvNorm = $"rvNorm", rvNormData = $"rvNormData"//, rvMask = $"rvMask"
	SVAR ppmOutputs
	Make/O/N=(nREE) rvAvgData, rvAvgNormData, rvMask, rvNorm, rvData, rvNormData
		
	Wave activeElements = $"activeElements"
	
	Variable i
	For (i = 0; i < nREE; i = i + 1)
		If (activeElements[i] !=1)
			rvMask[i] = Nan
		Else
			rvMask[i] = 1
		EndIf
	EndFor

	String usefulIntegrations = RVGetListOfUsefulIntegrations()
	String MatrixName
	
	Prompt MatrixName, "Which Integration Type? ", popup, usefulIntegrations
	DoPrompt/HELP="" "REEView", MatrixName
	If (V_Flag)
		Return -1
	EndIf
	
	// Get some stuff from Iolite
	Wave index_time = $ioliteDFpath("CurrentDRS", "Index_Time")
	//SVAR MatrixName = root:Packages:iolite:traces:MatrixName
	Wave aim = $ioliteDFpath("integration", "m_" + MatrixName)	
	Variable NoOfIntegrations = DimSize(aim,0) 

	// Set the normalization data
	RVSetNormWave("rvNorm")

	If (FindListItem("All_REE", WinList("*", ";", "")) == -1)
		Display/N=All_REE/K=1
	EndIf
	
	SVAR dataLocator

	// Set the locations and label data
	Wave reeLocations = $dataLocator
	Wave reeLabels = $"reeElements"
	
	Variable reeMax, reeMin
	
	ColorTab2wave $"ColdWarm"
	Wave M_colors
	Variable ncolors = DimSize(M_colors,0)
	
	For (i = 1; i < NoOfIntegrations; i = i + 1)
		String intname = "rvAvgData" + num2str(i)
		String intnormname = "rvAvgNormData" + num2str(i)
		Make/O/N=(nREE) $intname, $intnormname
		
		// Determine the current integration's range:	
		Variable startTime = (aim[i][0][0] - aim[i][0][1])
		Variable stopTime= (aim[i][0][0] + aim[i][0][1])
		Variable startIndex = ForBinarySearch(index_time, startTime) + 1
		Variable stopIndex = ForBinarySearch(index_time, stopTime)		
		
		Variable j
		For (j = 0; j < nREE; j = j + 1)
			String curCh = StringFromList(j, ppmOutputs)
			Wave rvAvgData = $intname
			
			rvAvgData[j] = RVGetIntegrationFromIolite(curCh, MatrixName, i, "resultWave")
				
		EndFor
		
		Wave rvAvgDataNorm = $intnormname
		
		rvAvgDataNorm = rvMask*rvAvgData/rvNorm
		Variable ThisCIndex = (i/NoOfIntegrations)*ncolors
		AppendToGraph/W=All_REE/c=(M_colors[ThisCIndex][0],M_colors[ThisCIndex][1],M_colors[ThisCIndex][2]) rvAvgDataNorm vs reeLocations
		
		If (WaveMin(rvAvgDataNorm) < reeMin || i == 1)
			reeMin = WaveMin(rvAvgDataNorm)
		EndIf
		
		If (WaveMax(rvAvgDataNorm) > reeMax || i == 1)
			reeMax = WaveMax(rvAvgDataNorm)
		EndIf
		
	EndFor


	// Modify graph characteristics
	ModifyGraph userticks(bottom)={reeLocations, reeLabels}	
	ModifyGraph/W=All_REE log(left)=1
	ModifyGraph/W=All_REE mirror=2,standoff=0;DelayUpdate
	Label/W=All_REE left "Spot / CI";DelayUpdate
//	Label/W=All_REE bottom "Element"	
	ModifyGraph/W=All_REE mode=4,marker=19	
	ModifyGraph/W=All_REE width=500, height=400
	ModifyGraph/W=All_REE gFont="Helvetica",gfSize=18
	ModifyGraph/W=All_REE grid(left)=2
	SetAxis/W=All_REE bottom WaveMin(reeLocations)-0.5, WaveMax(reeLocations)+0.5
	SetAxis/W=All_REE left 10^floor(log(reeMin)), 10^ceil(log(reeMax))
	
End

//------------------------------------------------------------------------
// Get a list of integrations that actually have some integrations set
//------------------------------------------------------------------------
Function/S RVGetListOfUsefulIntegrations()
	SVAR ListOfAvailableIntegrations = root:Packages:iolite:integration:ListOfIntegrations	
	String UsefulIntegrations = ""
	
	Variable i
	For (i = 0; i < ItemsInList(ListOfAvailableIntegrations); i = i + 1)
		Wave aim = $ioliteDFpath("integration", "m_" + StringFromList(i, ListOfAvailableIntegrations))
		Variable NoOfIntegrations = DimSize(aim,0)-1
		
		If (NoOfIntegrations > 0 && CmpStr(StringFromList(i,ListOfAvailableIntegrations),"Baseline_1") != 0 )
			UsefulIntegrations = UsefulIntegrations + StringFromList(i, ListOfAvailableIntegrations) + ";"
		EndIf
	EndFor
	
	Return UsefulIntegrations + ";Output_2"
End


Function RVMinMaxREE()

	RVEnsureInit()
	
	NVAR nREE
	
	Wave rvData = $"rvData", rvNorm = $"rvNorm", rvNormData = $"rvNormData", rvMask = $"rvMask"
	SVAR ppmOutputs
	Make/O/N=(nREE) rvAvgData, rvAvgNormData
		
	Wave activeElements = $"activeElements"
	
	Variable i
	For (i = 0; i < nREE; i = i + 1)
		If (activeElements[i] !=1)
			rvMask[i] = Nan
		Else
			rvMask[i] = 1
		EndIf
	EndFor
	
	// Get some stuff from Iolite
	Wave index_time = $ioliteDFpath("CurrentDRS", "Index_Time")
	String MatrixName = RVGetMatrixName()
	Wave aim = $ioliteDFpath("integration", "m_" + MatrixName)	
	Variable NoOfIntegrations = DimSize(aim,0) 

	// Set the normalization data
	RVSetNormWave("rvNorm")

	Display/N=MinMax_REE
	SVAR dataLocator

	// Set the locations and label data
	Wave reeLocations = $dataLocator
	Wave reeLabels = $"reeElements"	
	
	Make/O/N=(nREE) rvMinData, rvMaxData, rvMinDataNorm, rvMaxDataNorm
	rvMinData = inf
	rvMaxData = -inf
	rvMinDataNorm = inf
	rvMaxDataNorm = -inf
	
	For (i = 1; i < NoOfIntegrations; i = i + 1)
		String intname = "rvAvgData" + num2str(i)
		String intnormname = "rvAvgNormData" + num2str(i)
		Make/O/N=(nREE) $intname, $intnormname
		
		// Determine the current integration's range:	
		Variable startTime = (aim[i][0][0] - aim[i][0][1])
		Variable stopTime= (aim[i][0][0] + aim[i][0][1])
		Variable startIndex = ForBinarySearch(index_time, startTime) + 1
		Variable stopIndex = ForBinarySearch(index_time, stopTime)		
		
		Variable j
		For (j = 0; j < nREE; j = j + 1)
			String curCh = StringFromList(j, ppmOutputs)
			Wave rvAvgData = $intname
			
			rvAvgData[j] = RVGetIntegrationFromIolite(curCh, MatrixName, i, "resultWave")
			if (rvAvgData[j] < rvMinData[j])
				rvMinData[j] = rvAvgData[j]
			EndIf
			
			if (rvAvgData[j] > rvMaxData[j])
				rvMaxData[j] = rvAvgData[j]
			EndIf
				
		EndFor
		
		Wave rvAvgDataNorm = $intnormname
		
		rvAvgDataNorm = rvMask*rvAvgData/rvNorm

		AppendToGraph/W=MinMax_REE rvAvgDataNorm vs reeLocations
	EndFor
	
	rvMinDataNorm = rvMask*rvMinData/rvNorm
	rvMaxDataNorm = rvMask*rvMaxData/rvNorm
	AppendToGraph/W=MinMax_REE rvMinDataNorm vs reeLocations
	AppendToGraph/W=MinMax_REE rvMaxDataNorm vs reeLocations

	// Modify graph characteristics
	ModifyGraph userticks(bottom)={reeLocations, reeLabels}	
	ModifyGraph/W=MinMax_REE log(left)=1
	ModifyGraph/W=MinMax_REE mirror=2,standoff=0;DelayUpdate
	Label/W=MinMax_REE left "Integration / Normalization";DelayUpdate
	Label/W=MinMax_REE bottom "Element"	
	ModifyGraph/W=MinMax_REE mode=4,marker=19	
	ModifyGraph/W=MinMax_REE width=500, height=400
	ModifyGraph/W=MinMax_REE gFont="Helvetica",gfSize=14
	ModifyGraph/W=MinMax_REE grid(left)=2
	SetAxis/W=MinMax_REE bottom WaveMin(reeLocations), WaveMax(reeLocations)
	//SetAxis/W=REEPanel#Live_REE bottom reeLocations[0], reeLocations[13]
	

End

Function MakeBlankREEDiagram(GraphName)
	String GraphName
	
	NewDataFolder/O/S root:REEDiagram
	
	Variable nREE = 14	
	
	// Make a wave for elements
	Make/O/N=(nREE)/T REELabels
	REELabels = {"La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu"}
	
	// Make a wave for ionic radii (not sure what the units are here, or whether it is correct?)
	Make/O/N=(nREE) REEIonicRadii
	REEIonicRadii = {1.032, 1.01, 0.99, 0.983, 0.97, 0.947, 0.938, 0.923, 0.912, 0.901, 0.89, 0.88, 0.868, 0.861}
	
	// Make a wave for inverse ionic radii
	Make/O/N=(nREE) REEInvIonicRadii
	REEInvIonicRadii = 1/REEIonicRadii	
	
	// Make a wave for ree atomic numbers
	Make/O/N=(nREE) REEAtomicNumbers
	REEAtomicNumbers = {57, 58, 59, 60, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71 }

	Display/N=$GraphName

End

#include <Image Common>

// ************ Image ROI **********************


Function RVROIPanel()

	DoWindow/F RVImageROIPanel
	if( V_Flag==1 )
		return 0
	endif

	String igName= WMTopImageGraph()
	if( strlen(igName) == 0 )
		DoAlert 0,"No image plot found"
		return 0
	endif

	NewPanel /K=1 /W=(563,327,744,514) as "ROI"
	DoWindow/C RVImageROIPanel
	AutoPositionWindow/E/M=1/R=$igName
	ModifyPanel fixedSize=1
	Button StartROI,pos={14,9},size={150,20},proc=RVRoiDrawButtonProc,title="Start ROI Draw"
	Button StartROI,help={"Adds drawing tools to top image graph. Use rectangle, circle or polygon."}
	Button clearROI,pos={14,63},size={150,20},proc=RVRoiDrawButtonProc,title="Erase ROI"
	Button clearROI,help={"Erases previous ROI. Not undoable."}
	Button FinishROI,pos={14,35},size={150,20},proc=RVRoiDrawButtonProc,title="Finish ROI"
	Button FinishROI,help={"Click after you are finished editing the ROI"}
	Button saveROICopy,pos={14,92},size={150,20},proc=RVsaveRoiCopyProc,title="Save ROI Copy"
end

// the following function creates the roi wave and saves it in the same data folder as the top
// image wave.

Function RVsaveRoiCopyProc(ctrlName) : ButtonControl
	String ctrlName
	
	String topWave=WMGetImageWave(WMTopImageGraph())
	WAVE/Z ww=$topWave
	if(WaveExists(ww)==0)
		return 0
	endif
	
	String saveDF=GetDataFolder(1)
	String waveDF=GetWavesDataFolder(ww,1 )
	SetDataFolder waveDF
	
	ImageGenerateROIMask $WMTopImageName()		
	SetDataFolder saveDF
end

Function RVRoiDrawButtonProc(ctrlName) : ButtonControl
	String ctrlName

	String ImGrfName= WMTopImageGraph()
	if( strlen(ImGrfName) == 0 )
		return 0
	endif
	
	DoWindow/F $ImGrfName
	if( CmpStr(ctrlName,"StartROI") == 0 )
		ShowTools/A rect
		SetDrawLayer ProgFront
		Wave w= $WMGetImageWave(ImGrfName)		// the target matrix
		String iminfo= ImageInfo(ImGrfName, NameOfWave(w), 0)
		String xax= StringByKey("XAXIS",iminfo)
		String yax= StringByKey("YAXIS",iminfo)
		SetDrawEnv linefgc= (3,52428,1),fillpat= 0,xcoord=$xax,ycoord=$yax,save
	endif
	if( CmpStr(ctrlName,"FinishROI") == 0 )
		GraphNormal
		HideTools/A
		SetDrawLayer UserFront
		DoWindow/F RVImageROIPanel
	endif
	if( CmpStr(ctrlName,"clearROI") == 0 )
		GraphNormal
		SetDrawLayer/K ProgFront
		SetDrawLayer UserFront
		DoWindow/F RVImageROIPanel
	endif
End

Function MakeREEPlotFromROI(MapGraphName)
	String MapGraphName
	
	Wave/Z mapw= $WMGetImageWave(MapGraphName)	
	print NameOfWave(mapw)
	NewDataFolder/O/S root:REEDiagram
	
	Variable nREE = 14
	Make/O/N=(nREE)/T REELabels
	REELabels = {"La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu"}
	// Make a wave for ree atomic numbers
	Make/O/N=(nREE) REEAtomicNumbers
	REEAtomicNumbers = {57, 58, 59, 60, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71 }	
	
//	Wave REEAtomicNumbers = $"REEAtomicNumbers"
//	String NormStr = "MUQ_MK10"
	String NormStr = "CI_MS95"
	

	
	// Make list of ppmOutputs
	SVAR outputChannels = root:Packages:iolite:output:ListOfOutputChannels
	String ppmOutputs = ""
	
	Variable nOutputs = ItemsInList(outputChannels)-1
	
	Variable i
	For (i = 0; i < nOutputs; i = i + 1)
		String curOutput = StringFromList(i, outputChannels)
		
		String curOutputStripped = curOutput[0,1]
	//	print curOutput, curOutputStripped		
		If (strsearch(curOutputStripped,"_",0) != -1)
			curOutputStripped = curOutputStripped[0]
			Continue
		EndIf

		FindValue/TEXT=curOutputStripped/TXOP=1 REELabels
		If ( strsearch(curOutput, "ppm", 0) != -1 && V_value != -1)
			ppmOutputs = ppmOutputs + curOutput + ";"
		EndIf
	EndFor				
	
	print "Found these REE:", ppmOutputs
	
	// Loop through REE and use mask to generate values
	String uniqueDataName = UniqueName("Map_REEData", 1, 0)
	Make/O/N=(nREE) $(uniqueDataName)
	Wave REEData = $(uniqueDataName)
	
	// Get REE data
	For (i = 0; i < nREE; i = i + 1)
		String curCh = StringFromList(i, ppmOutputs)
		Wave CurrentMap = $ioliteDFpath("images",curCH+"_Map_Interp")
		print i, curCh+"_Map_Interp", REELabels[i], RVGetNormValue(NormStr, REELabels[i])
		ImageGenerateROIMask/E=1/I=0/W=$MapGraphName $NameOfWave(mapw)
		Wave M_ROIMask
		ImageStats/R=M_ROIMask CurrentMap
		Variable CurrentValue = V_avg
		REEData[i] = CurrentValue/RVGetNormValue(NormStr, REELabels[i])
	EndFor
	
	// Make a blank REE plot if it doesn't exist:
	DoWindow/F MapREE
	if (V_flag!=1)
		MakeBlankREEDiagram("MapREE")	
	EndIf
	
	AppendToGraph/W=MapREE REEData vs REEAtomicNumbers
	ModifyGraph/W=MapREE log(left)=1, mirror=2, standoff=0
	ModifyGraph/W=MapREE userticks(bottom)={REEAtomicNumbers, REELabels}
End


Function AddDataToREEDiagram(MatrixName, IntNo)
	String MatrixName
	Variable IntNo
	
	NewDataFolder/O/S root:Packages:REEView
	
	Wave/T REELabels = $"REELabels"
	Wave REEAtomicNumbers = $"REEAtomicNumbers"
	String NormStr = "CI_MS95"
	
	Wave aim = $ioliteDFpath("integration", "m_" + MatrixName)	
	Variable NoOfIntegrations = DimSize(aim,0) 
	
	print NoOfIntegrations
	If (IntNo > NoOfIntegrations)
		Return -1
	EndIf
	
	Variable nREE = 14
	
	// Make list of ppmOutputs
	SVAR outputChannels = root:Packages:iolite:output:ListOfOutputChannels
	String ppmOutputs = ""
	
	Variable nOutputs = ItemsInList(outputChannels)-1
	
	Variable i
	For (i = 0; i < nOutputs; i = i + 1)
		String curOutput = StringFromList(i, outputChannels)
		
		String curOutputStripped = curOutput[0,1]
		print curOutput, curOutputStripped		
		If (strsearch(curOutputStripped,"_",0) != -1)
			curOutputStripped = curOutputStripped[0]
			Continue
		EndIf

		FindValue/TEXT=curOutputStripped/TXOP=1 REELabels
		If ( strsearch(curOutput, "ppm", 0) != -1 && V_value != -1)
			ppmOutputs = ppmOutputs + curOutput + ";"
		EndIf
	EndFor			
	
	
	Make/O/N=(nREE) $(MatrixName+"_"+num2str(IntNo)+"_REEData")
	Wave REEData = $(MatrixName+"_"+num2str(IntNo)+"_REEData")
	
	// Get REE data
	For (i = 0; i < nREE; i = i + 1)
		String curCh = StringFromList(i, ppmOutputs)
		REEData[i] = RVGetIntegrationFromIolite(curCh, MatrixName, IntNo, "ResultWave")/RVGetNormValue(NormStr,REELabels[i])
	EndFor
	
	AppendToGraph REEData vs REEAtomicNumbers
	ModifyGraph log(left)=1, mirror=2, standoff=0
	ModifyGraph userticks(bottom)={REEAtomicNumbers, REELabels}
End

Function AddAllToREEDiagram(MatrixName)
	String MatrixName
	
	Wave aim = $ioliteDFpath("integration", "m_" + MatrixName)	
	Variable NoOfIntegrations = DimSize(aim,0) 
	
	Variable i
	For ( i = 0; i < NoOfIntegrations; i = i + 1)
		AddDataToREEDiagram(MatrixName, i)
	EndFor
	
End

Function AddAverageToREEDiagram(MatrixName)
	String MatrixName
	
	NewDataFolder/O/S root:REEDiagram
	
	Wave/T REELabels = $"REELabels"
	Wave REEAtomicNumbers = $"REEAtomicNumbers"
	String NormStr = "MUQ_MK10"
	
	Wave aim = $ioliteDFpath("integration", "m_" + MatrixName)	
	Variable NoOfIntegrations = DimSize(aim,0) 
	
	print NoOfIntegrations
	
	Variable nREE = 14
	
	// Make list of ppmOutputs
	SVAR outputChannels = root:Packages:iolite:output:ListOfOutputChannels
	String ppmOutputs = ""
	
	Variable nOutputs = ItemsInList(outputChannels)	
	
	Variable i
	For (i = 0; i < nOutputs; i = i + 1)
		String curOutput = StringFromList(i, outputChannels)
		
		String curOutputStripped = curOutput[0,1]
		
		If (strsearch(curOutputStripped,"_",0) != -1)
			curOutputStripped = curOutputStripped[0]
			Continue
		EndIf
		
		FindValue/TEXT=curOutputStripped/TXOP=1 REELabels
		If ( strsearch(curOutput, "ppm", 0) != -1 && V_value != -1)
			ppmOutputs = ppmOutputs + curOutput + ";"
		EndIf
	EndFor			
	
	
	Make/O/N=(nREE) $(MatrixName+"_REEData")
	Wave REEData = $(MatrixName+"_REEData")
	REEData = 0
	
	//print ppmOutputs
	// Get REE data
	For (i = 0; i < nREE; i = i + 1)
		String curCh = StringFromList(i, ppmOutputs)
		Variable j
		For (j = 1; j <= NoOfIntegrations; j = j + 1)
			REEData[i] += RVGetIntegrationFromIolite(curCh, MatrixName, j, "ResultWave")/RVGetNormValue(NormStr,REELabels[i])
			//print REEData[i]
		EndFor
	EndFor
	
	REEData = REEData/NoOfIntegrations
	
	AppendToGraph REEData vs REEAtomicNumbers
	ModifyGraph log(left)=1, mirror=2, standoff=0
	ModifyGraph userticks(bottom)={REEAtomicNumbers, REELabels}
End

Function/S RVGetMatrixName()

	SVAR MatrixName = root:Packages:iolite:traces:MatrixName
	
	If (GrepString(ks_VersionOfThisIcpmsPackage, "3.") == 1)
		String CurrentTab = GetUserData("IoliteMainWindow", "", "currentTab" )
		//Get current tab name
		Wave/T SettingsWave = $IoliteDFpath("IoliteGlobals", "TabSettings_" + CurrentTab) //Current settings wave
		Return SettingsWave[7]
	Else 
		Return MatrixName
	EndIf
End

Function RVGetActiveIntNum()

	If (GrepString(ks_VersionOfThisIcpmsPackage, "3.")==1)
		NVAR ActiveIntNum = root:Packages:iolite:Globals:ActiveSelectionMatrixRow
	Else
		NVAR ActiveIntNum = root:Packages:iolite:traces:IntegNumber
	EndIf
	
	Return ActiveIntNum
End