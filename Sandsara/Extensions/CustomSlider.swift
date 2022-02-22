import UIKit

class CustomSlider: UISlider {

    private var tool_tip: ToolTipPopupView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.initToolTip()
    }
    
    private func initToolTip() {
        tool_tip = ToolTipPopupView.init(frame: CGRect.zero)
        tool_tip?.backgroundColor = UIColor.clear
        tool_tip?.draw(CGRect.zero)
        self.addSubview(tool_tip!)
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        
        let knobRect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        
        let popupRect = knobRect.offsetBy(dx: 0, dy: -(knobRect.size.height))
        tool_tip?.frame = popupRect.offsetBy(dx: 0, dy: 0)
        tool_tip?.setValue(value: self.value)
        
        return knobRect
    }
}

class ToolTipPopupView: UIView {
    
    private var toolTipValue: NSString?
    
    override func draw(_ rect: CGRect) {
        
        if toolTipValue != nil {
            
            let paraStyle = NSMutableParagraphStyle.init()
            paraStyle.lineBreakMode = .byWordWrapping
            paraStyle.alignment = .center
            
            let textAttributes = [NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 10), NSAttributedString.Key.paragraphStyle: paraStyle, NSAttributedString.Key.foregroundColor: UIColor.white]
            
            if let s: CGSize = toolTipValue?.size(withAttributes: textAttributes as [NSAttributedString.Key : Any]) {
                let yOffset = s.height
                let textRect = CGRect.init(x: self.bounds.origin.x, y: yOffset, width: self.bounds.size.width, height: s.height)
                

                toolTipValue?.draw(in: textRect, withAttributes: textAttributes as [NSAttributedString.Key : Any])
            }
        }
    }
    
    func setValue(value: Float) {
        toolTipValue = NSString.init(format: "%d", Int(value))
        self.setNeedsDisplay()
    }
}
