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

  func render(width: Int, height: Int, scale: Double?, x: Int?, y: Int?, compressFormat: CompressFormat, backgroundColor: UIColor) -> Page.DataResult? {
    let pageRect = page.getBoxRect(.mediaBox)
    let scaleFactor = scale ?? 1

    var image: UIImage
    let size = CGSize(width: Double(width) * scaleFactor, height: Double(height) * scaleFactor)
    let scaleCGFloat = CGFloat(scaleFactor)

    if #available(iOS 10.0, *) {
      let renderer = UIGraphicsImageRenderer(size: size)

      image = renderer.image {ctx in
        UIColor.white.set()
        ctx.fill(CGRect(x: 0, y: 0, width: Double(width) * scaleFactor, height: Double(height) * scaleFactor))

        ctx.cgContext.translateBy(x: x != nil ? CGFloat(x!) : 0.0, y: pageRect.size.height * scaleCGFloat)
        ctx.cgContext.scaleBy(x: scaleCGFloat, y: -scaleCGFloat)

        ctx.cgContext.drawPDFPage(page)
      }
    } else {
      // Fallback on earlier versions
      UIGraphicsBeginImageContext(size)
      let ctx = UIGraphicsGetCurrentContext()!
      UIColor.white.set()
      ctx.fill(CGRect(x: 0, y: 0, width: Double(width) * scaleFactor, height: Double(height) * scaleFactor))

      ctx.translateBy(x: 0.0, y: pageRect.size.height * scaleCGFloat)
      ctx.scaleBy(x: scaleCGFloat, y: -scaleCGFloat)

      ctx.drawPDFPage(page)

      image = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
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
        width: width,
        height: height,
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
