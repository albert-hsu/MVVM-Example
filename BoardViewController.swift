import UIKit

class BoardViewController: UIViewController {
    let frame: CGRect
    var viewModel: BoardViewModel
    var bounds: CGRect {
        view.bounds
    }
    var marks: Dictionary<Board.Position, CALayer> = [:]
    
    init(frame: CGRect, viewModel: BoardViewModel) {
        precondition(frame.width == frame.height)
        
        self.frame = frame
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.frame = frame
        
        let boardImageView = UIImageView(image: UIImage(named: "Hash"))
        // The image is not vertically centered. shifted a little bit.
        boardImageView.frame = view.bounds.offsetBy(dx: 0, dy: -5)
        boardImageView.backgroundColor = .clear
        view.addSubview(boardImageView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        view.addGestureRecognizer(tap)
        
        bind(to: self.viewModel)
        viewModel.viewDidLoad()
    }
    
    private func bind(to viewModel: BoardViewModel) {
        viewModel.move.observe(on: self) { [weak self] in
            self?.draw(move: $0, color: UIColor.black)
        }
        viewModel.status.observe(on: self) { [weak self] in
            self?.statusDidChange($0)
        }
    }
    
    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        guard let view = recognizer.view else {
            return
        }
        
        let point = recognizer.location(in: view)
        if let position = self.position(point: point) {
            viewModel.fill(position: position)
        }
    }
    
    private func draw(move: Board.Move?, color: UIColor) {
        guard let move else {
            // fatalError()
            return
        }
        guard let layer = view?.layer else {
            fatalError()
        }
        
        let insets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        let duration: CFTimeInterval = 0.5
        let lineWidth: CGFloat = 6.0
        
        let bounds = rectangle(position: move.position, insets: insets)
        var path: UIBezierPath
        switch move.mark {
        case .nought:
            let clockwise = Bool.random(probibility: 0.5)
            let startAngle = CGFloat.random(in: Double.pi * 3.0 / 2.0 ... Double.pi * 2.0)
            let endAngle = startAngle + (clockwise ? Double.pi * 2.0 : -Double.pi * 2.0)
            path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: CGFloat(bounds.width / 2.0), startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        case .cross:
            path = UIBezierPath()
            if Bool.random(probibility: 0.8) {
                path.move(to: bounds.origin)
                path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
                path.move(to: CGPoint(x: bounds.maxX, y: bounds.minY))
                path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
            } else {
                path.move(to: CGPoint(x: bounds.maxX, y: bounds.minY))
                path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
                path.move(to: bounds.origin)
                path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
            }
            path.close()
        default:
            fatalError()
        }
        
        let shape = CAShapeLayer()
        shape.strokeColor = color.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = lineWidth
        shape.path = path.cgPath
        
        guard !marks.keys.contains(move.position) else {
            fatalError()
        }
        marks[move.position] = shape
        layer.addSublayer(shape)
        
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0
        anim.toValue = 1
        anim.duration = duration
        
        shape.add(anim, forKey: nil)
    }
    
    private func rectangle(position: Board.Position, insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)) -> CGRect {
        
        let length = bounds.width / 3.0
        
        let x: CGFloat = length * CGFloat(position.column) + insets.left
        let y: CGFloat = length * CGFloat(position.row) + insets.top
        let width: CGFloat = length - insets.left - insets.right
        let height: CGFloat = length - insets.top - insets.bottom
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func position(point: CGPoint) -> Board.Position? {
        let insets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let range = 0...2
        
        for r in range {
            for c in range {
                let position = Board.Position(row: r, column: c)
                if rectangle(position: position, insets: insets).contains(point) {
                    return position
                }
            }
        }
        return nil
    }
    
    func clear() {
        marks.forEach { (_: Board.Position, layer: CALayer) in
            layer.removeFromSuperlayer()
        }
        marks.removeAll()
    }
    
    func statusDidChange(_ status: Board.Status) {
        switch status {
        case .won(let mark, let `case`):
            marks.forEach { (pos: Board.Position, layer: CALayer) in
                if `case`.contains(pos) {
                    layer.removeFromSuperlayer()
                    marks.removeValue(forKey: pos)
                    draw(move: Board.Move(position: pos, mark: mark), color: UIColor.white)
                }
            }
            break
        case .drawn:
            break
        default:
            break
        }
    }

    func reset() {
        viewModel.reset()
        clear()
    }
}
