<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WingScan_withViewer_append.Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>WingScan Whitepaper: Appending</title>
    <!-- Script includes for Web Viewing -->
    <script src="/WebDocViewer/jquery-3.5.1.min.js" type="text/javascript"></script>
    <script src="/WebDocViewer/jquery-ui-1.14.0.min.js" type="text/javascript"></script>
    <script src="/WebDocViewer/raphael-min.js" type="text/javascript"></script>
    <script src="/WebDocViewer/clipboard.min.js" type="text/javascript"></script>
    <script src="/WebDocViewer/atalaWebDocumentViewer.js" type="text/javascript"></script>
    <!-- Style for Web Viewer -->
    <link href="/WebDocViewer/jquery-ui-1.14.0.min.css" rel="Stylesheet" type="text/css" />
    <link href="/WebDocViewer/atalaWebDocumentViewer.css" rel="Stylesheet" type="text/css" />
    <!-- Script includes for Web Capture -->
    <script src="/WebCapture/atalaWebCapture.js" type="text/javascript"></script>


    <script type="text/javascript">
    var _viewer = null;
    var _thumbs = null;

    // _append and _scanCount are needed for scan new vs scan add... 
    var _append = false;
    var _scanCount = 0;

    // Initialize Web Scanning and Web Viewing... this will run at startup
    $(function () {
        _viewer = new Atalasoft.Controls.WebDocumentViewer({
            parent: $('#_containerViewer'), // parent container to put the viewer in
            toolbarparent: $('#_toolbar1'), // parent container to put the viewer toolbar in
            serverurl: '/WebDocViewerHandler.ashx', // server handler url to send image requests to
            allowannotations: true, // flag to enable annotations
            savepath: 'Saved/', // relative url to save annotation data to
            showscrollbars: true,
            forcepagefit: true
        });
        _thumbs = new Atalasoft.Controls.WebDocumentThumbnailer({
            parent: $('#_containerThumbs'),
            serverurl: '/WebDocViewerHandler.ashx',
            documenturl: '/images/1_page_bwtext_with_color_logo.tif',
            allowannotations: true,
            viewer: _viewer,
            allowdragdrop: true,
            showscrollbars: true
        });
        try {
            Atalasoft.Controls.Capture.WebScanning.initialize({
                handlerUrl: 'WebCaptureHandler.ashx',
                onScanStarted: function () {
                    // When we start a new scan, we want to make this count zeroed out so that we get an accurate count
                    _scanCount = 0;
                },
                onImageAcquired: function (index, image) {
                    // this just increments the count each time an image is aqcuired.. 
                    // this is how we will know how many pages were scanned so we can properly 
                    // insert later
                    // NOTE THIS EVENT DOES NOT FIRE IF discardBlankPages was true and the page scanned was discarded
                    // this allows us to have a correct count for numer of pages scanned
                    _scanCount++;
                },
                onUploadCompleted: function (eventName, eventObj) {
                    // we only do this if the upload completed successfully
                    if (eventObj.success) {

                        // You will need to adjust this to point to the actual location where  
                        // the files are being uploaded/scanned into
                        // atala-capture-upload is simply the component's default location
                        var folderWhereFilesUploadTo = "/atala-capture-upload/";

                        // we need to know the page count so that we can avoid trying to append (add) when 
                        // there are no pages.. attempting the _thumbs.document.insertPages
                        var pageCount = _thumbs.getDocumentInfo().count;

                        // we can not insert if there are no pages existing so we will check
                        // and switch to "new scan" if there aren't pages
                        if (_append && pageCount > 0) {
             
                            var destIndex = pageCount
                            var srcIndices = makeSrcArray(_scanCount);

                            //alert("Inserting " + _scanCount + " pages at index " + destIndex);

                            _thumbs.document.insertPages(folderWhereFilesUploadTo + eventObj.documentFilename, srcIndices, destIndex);
                        } else {
                            _thumbs.OpenUrl(folderWhereFilesUploadTo + eventObj.documentFilename);
                        }
                    }
                },
                onUploadError: scanErrorHandler,
                onScanError: scanErrorHandler,
                scanningOptions: { applyVRS: false, showScannerUI: false }
            });
        } catch (error) {
            alert('Thrown error: ' + error.description);
            Atalasoft.Controls.Capture.WebScanning.dispose();
        }
    });
    
    // This is needed because the insertPages call needs an array of indices
    // so we pass in a number of pages to generate the needed src indicies array
    function makeSrcArray(count) {
        var returnArray = new Array();
        for (var i = 0; i < count; i++) {
            returnArray.push(i);
        }
        return returnArray;
    }

    // this is needed because if you do not use this code, then only the system default scanner will ever be used
    // We will be adding the append value to set here
    function scanWithSelectedScanner(append) {

        // setting the _append var to true/false to determine if we will scan new (false) or append to existing scan (true)
        if (append) {
            _append = true;
        } else {
            _append = false;
        }

        // this is the standard scan with selected scanner code
        Atalasoft.Controls.Capture.WebScanning.scanningOptions.scanner = $('.atala-scanner-list').val();
        Atalasoft.Controls.Capture.WebScanning.scan();
    }

  

    /// This is an updated handler with more sophisticated handling of certain errors
    /// if you are interested in all possible errors, check this out
    /// https://atalasoft.github.io/web-capture-service/Atalasoft.Controls.Capture.html#.Errors
    ///
    function scanErrorHandler(msg, params) {
        switch (msg) {
            case Atalasoft.Controls.Capture.Errors.noTwain:
                alert("This web capture application requires that you have at least one valid TWAIN device installed and configured. Please ensure you install the TWAIN driver for your scanner device(s) then re-visit this site.");
                break;
            case Atalasoft.Controls.Capture.Errors.oldWindowsService:
                alert("The version of Kofax WebCapture Service running on the multiuser system you're using is out of date. Please contact your system administrator.");
                break;
            case Atalasoft.Controls.Capture.Errors.webServiceMissed:
                alert("The Kofax WebCapture Service on the multiuser system you're using is not running. Please contact your system administrator.");
                break;
            case Atalasoft.Controls.Capture.Errors.noPlugin:
                var installerUrl = window.location.protocol + "//" + window.location.host + "/WebCapture/" + params.filename;
                window.open(installerUrl, '_downloadService');
                alert(
                    "The WingScan Web Scanning service is not available. \n\n" +
                    "If the download doesn't start automatically, please download from " + installerUrl + "\n\n" +
                    "If you are not prompted to install, the service may be installed but not running. \n\n" +
                    "enable it by running from START->All Programs->Kofax Web Capture Service->Kofax Web Capture Service  \n\n" +
                    "Refresh your browser when completed.");
                break;
            case Atalasoft.Controls.Capture.Errors.oldPlugin:
                var installerUrl = window.location.protocol + "//" + window.location.host + "/WebCapture/" + params.filename;
                window.open(installerUrl, '_downloadService');
                alert(
                    "The WingScan Web Scanning service is out of date.<br />" +
                    "If the download does not begin automatically, please go to " +
                    params.filename);
                break;
            default:
                alert(msg);
                break;
        }
    }
</script>

</head>
<body>
    <form id="form1" runat="server">
    <div id="scanDiv">
        <h1>Basic WingScan Web Capture Demo</h1>
        <h3>Using WingScan and WITH Viewer - Modified to add Appending</h3>
        <p>Select your scanner and click the scan button... the file will be uploaded to /atala-capture-upload/ with a unique filename (the filename will appear in the status below)</p>
        <p>&nbsp;</p>
        <p>Select Scanner:
            <select class="atala-scanner-list" disabled="disabled" name="scannerList" style="width:22em">
                <option selected="selected">(no scanners available)</option>
            </select>
            &nbsp;
            <!-- DO NOT USE <input type="button" class="atala-scan-button" value="Scan" /> -->
            <input type="button" id="scan_new" value="Scan New Document" onclick="scanWithSelectedScanner(false); return false;" />
            <input type="button" id="scan_append" value="Scan and Append" onclick="scanWithSelectedScanner(true); return false;" />
        </p>

    </div>
    <div style="width: 900px;">
    <div id="_toolbar1"></div>
    <div id="_containerThumbs" style="width: 180px; height: 600px;
    display: inline-block;"></div>
    <div id="_containerViewer" style="width: 710px; height: 600px;
    display: inline-block;"></div>
    </div>
    </form>
</body>
</html>
