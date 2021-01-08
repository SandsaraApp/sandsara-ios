//
//  ColorGradientView.swift
//  Sandsara
//
//  Created by Tín Phan on 02/12/2020.
//

import UIKit
import SnapKit
import Foundation
import CoreGraphics

import UIKit.UIGestureRecognizerSubclass

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

enum PanDirection {
    case vertical
    case horizontal
}

class PanDirectionGestureRecognizer: UIPanGestureRecognizer {

    let direction: PanDirection

    init(direction: PanDirection, target: AnyObject, action: Selector) {
        self.direction = direction
        super.init(target: target, action: action)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if state == .began {
            let vel = velocity(in: view)
            switch direction {
            case .horizontal where abs(vel.y) > abs(vel.x):
                state = .cancelled
            case .vertical where abs(vel.x) > abs(vel.y):
                state = .cancelled
            default:
                break
            }
        }
    }
}

protocol ColorPointDragAble {
    func updateColor(atPoint: CGPoint)
    func showGradient(atPoint: CGPoint, color: UIColor)
}

class ColorPointView: UIView {
    var color: UIColor? {
        didSet {
            updateColor()
        }
    }
    var currentPoint: CGPoint?

    var minPoint: CGPoint?

    var maxPoint: CGPoint?

    var colorThumb: UIView?
    var lineView: UIView?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        lineView = UIView()
        colorThumb = UIView()
        addSubview(lineView!)
        lineView?.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.left.equalTo(11)
            $0.height.equalTo(14)
            $0.width.equalTo(2)
        }

        addSubview(colorThumb!)
        colorThumb?.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.top.equalTo(lineView!.snp.bottom)
            $0.leading.trailing.equalTo(0)
            $0.bottom.equalTo(-6)
        }


        colorThumb?.clipsToBounds = true

        updateColor()
    }

    override func awakeFromNib() {
    }

    override func draw(_ rect: CGRect) {
        colorThumb?.layer.cornerRadius = colorThumb!.bounds.size.width / 2
    }

    func updateColor() {
        lineView?.backgroundColor = color
        colorThumb?.backgroundColor = color
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        colorThumb?.layer.cornerRadius = colorThumb!.bounds.size.width / 2
    }
}

protocol ColorGradientViewDelegate: class {
    func firstPointTouch(color: UIColor)
    func secondPointTouch(color: UIColor)
    func showGradient(atPoint: CGPoint, color: UIColor)
}

class ColorGradientView: UIView {

    var color: ColorModel = ColorModel(position: PredifinedColor.one.posistion.map {
        Int($0)
    }, colors: PredifinedColor.one.colors.map {
        $0.hexString()
    }) {
        didSet {
            selectColor()
        }
    }

    var colors: [UIColor] = [] {
        didSet {
            updateColor()
        }
    }

    var cachedGradients: [UIColor] = []

    var locations = [CGFloat]()

    var showPoint: CGPoint = CGPoint.zero

    var firstPoint: CGPoint = CGPoint.zero

    var secondPoint: CGPoint = CGPoint(x: UIScreen.main.bounds.size.width - 27, y: 0)

    var isFirst: Bool = false

    var isLast: Bool = false

    var addCustomPoint = false

    var updateCustomPoint = false

    var deleteCustomPoint = false

    var gradientView: GradientView?

    var firstPointView: ColorPointView?

    var secondPointView: ColorPointView?

    var pointViews: [ColorPointView] = []

    weak var delegate: ColorGradientViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        gradientView = GradientView()
        gradientView?.mode = .linear
        gradientView?.direction = .horizontal

        addSubview(gradientView!)

        gradientView?.snp.makeConstraints {
            $0.left.equalTo(11)
            $0.right.equalTo(-11)
            $0.top.equalToSuperview()
            $0.height.equalTo(43)
        }

        firstPointView = ColorPointView()
        addSubview(firstPointView!)

        firstPointView?.snp.makeConstraints {
            $0.top.equalTo(43)
            $0.leading.equalToSuperview()
            $0.width.equalTo(24)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview()
        }

        secondPointView = ColorPointView()
        addSubview(secondPointView!)

        secondPointView?.snp.makeConstraints {
            $0.top.equalTo(43)
            $0.trailing.equalToSuperview()
            $0.width.equalTo(24)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview()
        }

        firstPointView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showFirstPoint)))
        secondPointView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showSecondPoint)))
        gradientView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showGradientGesture(_:))))
    }

    override func draw(_ rect: CGRect) {
        selectColor()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        secondPoint.x = gradientView?.frame.size.width ?? 0
    }

    func selectColor() {
        if addCustomPoint {
            return;
        }

        if updateCustomPoint {
            return;
        }

        gradientView?.locations = color.position.map {
            CGFloat($0) / 255.0
        }

        locations = color.position.map {
            CGFloat($0) / 255.0
        }

        for view in pointViews {
            view.removeFromSuperview()
        }

        pointViews.removeAll()


        var drawColors = color.colors.map { UIColor(hexString: $0) }
        if drawColors.count > 2 {
            drawColors.removeFirst()
            drawColors.removeLast()
        }

        var drawPositons = color.position.map {
            convertGradientPointToSystemPoint(x: CGFloat($0))
        }

        if drawPositons.count > 2 {
            drawPositons.removeFirst()
            drawPositons.removeLast()
        }
        guard drawColors.count == drawPositons.count else { return }
        for i in 0 ..< drawColors.count {
            addPoint(color: drawColors[i], xPoint: drawPositons[i])
        }

        // update max and min point
        if pointViews.count > 1 {
            for i in 0 ..< pointViews.count {
                if i == 0 {
                    pointViews[i].maxPoint = CGPoint(x: pointViews[i + 1].currentPoint?.x ?? 0.0  - 11, y: 30)
                    pointViews[i].minPoint = CGPoint(x: firstPoint.x + 11, y: 30)
                } else if i == pointViews.count - 1 {
                    pointViews[i].maxPoint = CGPoint(x: secondPoint.x - 11, y: 30)
                    pointViews[i].minPoint = CGPoint(x: pointViews[i - 1].currentPoint?.x ?? 0.0  + 11, y: 30)
                } else {
                    pointViews[i].maxPoint = CGPoint(x: pointViews[i + 1].currentPoint?.x ?? 0.0  - 11, y: 30)
                    pointViews[i].minPoint = CGPoint(x: pointViews[i - 1].currentPoint?.x ?? 0.0  + 11, y: 30)
                }
            }
        }

        gradientView?.colors = color.colors.map { UIColor(hexString: $0) }
        gradientView?.locations = locations
        firstPointView?.color = color.colors.map { UIColor(hexString: $0) }.first
        secondPointView?.color = color.colors.map { UIColor(hexString: $0) }.last
        cachedGradients = color.colors.map { UIColor(hexString: $0) }
    }

    func updateColor() {
        gradientView?.colors = colors
        gradientView?.locations = locations
        firstPointView?.color = colors.first
        secondPointView?.color = colors.last
        colorCommand()
    }

    func showColorThumb(colorThumbView: ColorPointView, isShow: Bool) {
        colorThumbView.isHidden = !isShow
        colorThumbView.alpha = isShow ? 1: 0
    }

    @objc func showFirstPoint() {
        cleanup(isShowAll: false)
        isFirst = true
        delegate?.firstPointTouch(color: colors.first ?? .clear)
    }

    @objc func showSecondPoint() {
        cleanup(isShowAll: false)
        isLast = true
        delegate?.secondPointTouch(color: colors.last ?? .clear)
    }

    @objc func showGradientGesture(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: gradientView)
        debugPrint("Touch point \(point.x), \(point.y)")


        if point.x > (firstPoint.x + 11) && point.x < (secondPoint.x - 11)  {
            cleanup(isShowAll: false)
            showPoint = point
            addCustomPoint = true
            delegate?.showGradient(atPoint: showPoint, color: getPixelColor(atPosition: showPoint))
        }
    }

    func cleanup(isShowAll: Bool) {
        isFirst = false
        isLast = false
        addCustomPoint = false
        updateCustomPoint = false
        deleteCustomPoint = false
        showPoint = .zero
        for subview in subviews {
            if let subview = subview as? ColorPointView {
                showColorThumb(colorThumbView: subview, isShow: isShowAll)
            }
        }
    }

    func updateFirstColor(color: UIColor) {
        var colors = self.colors
        colors.removeFirst()
        colors.insert(color, at: 0)
        self.colors = colors
        firstPointView?.color = color
        cachedGradients = colors
        cleanup(isShowAll: true)
    }

    func updateSecondColor(color: UIColor) {
        var colors = self.colors
        colors.removeLast()
        colors.insert(color, at: colors.count)

        self.colors = colors
        secondPointView?.color = color
        cachedGradients = colors
        cleanup(isShowAll: true)
    }

    func updateColor(color: UIColor) {
        cleanup(isShowAll: true)
    }

    func addColor(color: UIColor) {
        addPoint(color: color, xPoint: showPoint.x)
        var updatedColors = cachedGradients

        var index = 0

        // update point after add
        for i in 0 ..< pointViews.count {
            if pointViews[i].currentPoint?.x == showPoint.x {
                index = i
                if i == 0 {
                    pointViews[i].maxPoint = CGPoint(x: pointViews[i + 1].center.x - 24, y: 30)
                    pointViews[i].minPoint = CGPoint(x: firstPoint.x + 24, y: 30)
                } else if i == pointViews.count - 1 {
                    pointViews[i].maxPoint = CGPoint(x: secondPoint.x - 24, y: 30)
                    pointViews[i].minPoint = CGPoint(x: pointViews[i - 1].center.x + 24, y: 30)
                } else {
                    pointViews[i].maxPoint = CGPoint(x: pointViews[i + 1].center.x - 24, y: 30)
                    pointViews[i].minPoint = CGPoint(x: pointViews[i - 1].center.x + 24, y: 30)
                }
                break
            }
        }

        // update
        updatedColors.insert(color, at: index + 1)
        locations.insert(showPoint.x / secondPoint.x, at: index + 1)

        colors = updatedColors
        cachedGradients = colors
        cleanup(isShowAll: true)
    }

    func updatePointColor(color: UIColor) {
        var updatedColors = cachedGradients
        for i in 0 ..< pointViews.count {
            if pointViews[i].currentPoint?.x == showPoint.x {
                pointViews[i].color = color
                updatedColors[i + 1] = color
                break
            }
        }

        colors = updatedColors

        cachedGradients = colors

        cleanup(isShowAll: true)
    }

    func removeColor(color: UIColor) {
        var updatedColors = cachedGradients
        for i in 0 ..< pointViews.count {
            if pointViews[i].currentPoint?.x == showPoint.x {
                pointViews[i].removeFromSuperview()
                pointViews.remove(at: i)
                updatedColors.remove(at: i + 1)
                locations.remove(at: i + 1)
                break
            }
        }

        colors = updatedColors

        cachedGradients = colors

        cleanup(isShowAll: true)
    }

    func getPixelColor(atPosition:CGPoint) -> UIColor{
        var pixel:[CUnsignedChar] = [0, 0, 0, 0];
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let bitmapInfo = CGBitmapInfo(rawValue:    CGImageAlphaInfo.premultipliedLast.rawValue);
        let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue);

        context!.translateBy(x: -atPosition.x, y: -atPosition.y);
        layer.render(in: context!);
        let color:UIColor = UIColor(red: CGFloat(pixel[0])/255.0,
                                    green: CGFloat(pixel[1])/255.0,
                                    blue: CGFloat(pixel[2])/255.0,
                                    alpha: CGFloat(pixel[3])/255.0);

        return color;

    }

    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state{
        case .changed:
            // follow the pan
            let dCenter = gestureRecognizer.translation(in: self)
            guard let pointView = gestureRecognizer.view as? ColorPointView else { return }
            if (pointView.center.x + dCenter.x) < pointView.maxPoint?.x ?? 0 && (pointView.center.x + dCenter.x) > pointView.minPoint?.x ?? 0 {
                pointView.center = CGPoint(x: (pointView.center.x + dCenter.x), y: pointView.center.y)

                gestureRecognizer.setTranslation(.zero, in: pointView)
                for view in pointViews where pointView.currentPoint == view.currentPoint {
                    view.currentPoint = CGPoint(x: pointView.center.x - 11, y: pointView.center.y)
                }
                locations = [
                    self.firstPoint.x / self.secondPoint.x
                ] + self.pointViews.map {
                    ($0.currentPoint?.x ?? 0) / self.secondPoint.x
                } + [1]
                updateColor()
            }
        default: break

        }
    }

    func convertGradientPointToSystemPoint(x: CGFloat) -> CGFloat {
        return x * secondPoint.x / 255
    }

    func convertSystemPointToGradientPoint(x: CGFloat) -> CGFloat {
        return x * 255 / secondPoint.x
    }

    func pointToLocation(x: Float) -> Float {
        return x / 1.0
    }

    private func addPoint(color: UIColor, xPoint: CGFloat) {
        let pointView = ColorPointView()
        addSubview(pointView)

        pointView.snp.makeConstraints {
            $0.top.equalTo(43)
            $0.leading.equalTo(xPoint)
            $0.width.equalTo(24)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview()
        }
        pointView.currentPoint = CGPoint(x: xPoint, y: 30.0)
        pointView.color = color
        pointViews.append(pointView)

        pointViews.sort(by: {
            ($0.currentPoint?.x ?? 0) < ($1.currentPoint?.x ?? 0)
        })
        // TODO : check condtion here
        pointView.tag = pointViews.firstIndex(of: pointView) ?? 0

        let panGestureRecognizer = PanDirectionGestureRecognizer(direction: .horizontal,
                                                                 target: self,
                                                                 action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.cancelsTouchesInView = false
        pointView.addGestureRecognizer(panGestureRecognizer)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(handleTapGesture(_:)))
        pointView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
        let point = (sender.view as? ColorPointView)?.currentPoint ?? .zero
        debugPrint("Touch point \(point.x), \(point.y)")

        showPoint = point
        updateCustomPoint = true
        delegate?.showGradient(atPoint: showPoint, color: getPixelColor(atPosition: showPoint))
    }

    func colorCommand() {
        let position = locations.map { $0 * 255 }.map { Int($0) }.map { "\($0)" }.joined(separator: ",")

        let red = colors.map {
            $0.rgba().red * 255
        }.map { Int($0) }.map { "\($0)" }.joined(separator: ",")

        let blue = colors.map {
            $0.rgba().blue * 255
        }.map { Int($0) }.map { "\($0)" }.joined(separator: ",")

        let green = colors.map {
            $0.rgba().green * 255
        }.map { Int($0) }.map { "\($0)" }.joined(separator: ",")

        LedStripServiceImpl.shared
            .uploadCustomPalette(amoutColors: "\(colors.count)",
                                 postions: position,
                                 red: red,
                                 blue: blue,
                                 green: green)
    }
}
