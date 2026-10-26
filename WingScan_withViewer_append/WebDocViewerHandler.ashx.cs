using System;
using System.Web;
using Atalasoft.Imaging.WebControls;

namespace WingScan_withViewer_append
{
    public class WebDocViewerHandler : WebDocumentRequestHandler
    {
        public WebDocViewerHandler()
        {
            /// IMPORTANT!: This is added for security purposes - it fully disables file upload
            this.FileUpload += new FileUploadEventHandler(delegate(object sender, FileUploadEventArgs e) { e.Cancel = true; });
        }
    }
}