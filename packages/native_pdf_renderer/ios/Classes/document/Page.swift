class Page {
    let id: String
    let documentId: String
    let page: CGPDFPage
    let boxRect: CGRect

    init(id: String, documentId: String, renderer: CGPDFPage) {
        self.id = id
        self.documentId = documentId
        self.page = renderer
        self.boxRect = renderer.getBoxRect(.mediaBox)
    }

    var number: Int {
        get {
            return page.pageNumber
        }
    }

    var width: Int {
        get {
            return Int(boxRect.width)
        }
    }

    var height: Int {
        get {
            return Int(boxRect.height)
        }
    }

    var infoMap: [String: Any] {
        get {
            return [
                "documentId": documentId,
                "id": id,
                "pageNumber": Int32(number),
                "width": Int32(width),
                "height": Int32(height)
            ]
        }
    }

  func render(width: Int, height: Int, crop: CGRect?, compressFormat: CompressFormat, backgroundColor: UIColor) -> Page.DataResult? {
    let pageRect = page.getBoxRect(.mediaBox)
    let sx = CGFloat(width) / pageRect.width
    let sy = CGFloat(height) / pageRect.height

    var image: UIImage

    if #available(iOS 10.0, *) {
      let renderer = UIGraphicsImageRenderer(size: pageRect.size)
      
      image = renderer.image {ctx in
        UIColor.white.set()
        ctx.fill(pageRect)

        ctx.cgContext.translateBy(x: 0, y: pageRect.size.height * sy)
        ctx.cgContext.scaleBy(x: sx, y: -sy)

        ctx.cgContext.drawPDFPage(page)
      }
    } else {
      // Fallback on earlier versions
      UIGraphicsBeginImageContext(pageRect.size)
      let ctx = UIGraphicsGetCurrentContext()!
      UIColor.white.set()
      ctx.fill(pageRect)

      ctx.translateBy(x: 0.0, y: pageRect.size.height)
      ctx.scaleBy(x: 1.0, y: -1.0)

      ctx.drawPDFPage(page)

      image = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
    }

    if (crop != nil){
        // Perform cropping in Core Graphics
      guard let cutImageRef = image.cgImage!.cropping(to: crop!) else {
        print("Cropping rect is outside image!")
        return nil
      }

      image = UIImage(cgImage: cutImageRef)
    }
      
    let data: Data

    switch(compressFormat) {
      case CompressFormat.JPEG:
        guard let d = image.jpegData(compressionQuality: 1.0) else {
          print("Error while creating jpeg image.")
          return nil
        }
        data = d
        break;
      case CompressFormat.PNG:
        guard let d = image.pngData() else {
          print("Error while creating png image.")
          return nil
        }
        data = d
        break;
    }

    return Self.DataResult(
        width: (crop != nil) ? Int(crop!.width) : width,
        height: (crop != nil) ? Int(crop!.height) : height,
        data: data
    )
    }

    class DataResult {
        let width: Int
        let height: Int
        let data: Data

        init(width: Int, height: Int, data: Data) {
            self.width = width
            self.height = height
            self.data = data
        }
    }
}

enum CompressFormat: Int {
    case JPEG = 0
    case PNG = 1
}
