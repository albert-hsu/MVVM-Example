import Foundation

protocol BoardViewModelInput {
    func viewDidLoad()
    func fill(position: Board.Position)
    func reset()
}

protocol BoardViewModelOutput {
    var move: Observable<Board.Move?> { get }
    var whoseTurnText: Observable<String?> { get }
    var winnerAnnouncementText: Observable<String?> { get }
    var status: Observable<Board.Status> { get }
}

protocol BoardViewModel: BoardViewModelInput, BoardViewModelOutput { }

class MyBoardViewModel: BoardViewModel {
    private var processing = true
    
    private var first: Board.Mark
    private var robotFirst: Bool
    private var yourTurn: Bool {
        if board.turn == .none {
            return !robotFirst
        } else {
            return board.turn == yourMark
        }
    }
    private var yourMark: Board.Mark {
        robotFirst ? first.next : first
    }
    
    private var board: BoardModel
    private var robot: RobotModel
    
    private var task: DispatchWorkItem?
    
    var move: Observable<Board.Move?> = Observable(nil)
    var whoseTurnText: Observable<String?> = Observable(nil)
    var winningCase: Observable<Set<Board.Position>?> = Observable(nil)
    var winnerAnnouncementText: Observable<String?> = Observable(nil)
    var status: Observable<Board.Status> = Observable(.ongoing)
    
    required init(boardModel: BoardModel, robotModel: RobotModel) {
        self.board = boardModel
        self.robot = robotModel
        
        first = .nought
        robotFirst = false
        whoseTurnText.value = yourTurn ? "your_turn".localized() : "opponent's_turn".localized()
    }
    
    func viewDidLoad() {
        self.board.move.observe(on: self) { [weak self] in self?.didMove($0) }
    }
    
    func fill(position: Board.Position) {
        guard yourTurn else {
            return
        }
        let mark = board.turn != .none ? board.turn : first
        board.fill(move: Board.Move(position: position, mark: mark))
    }
    
    func reset() {
        task?.cancel()
        
        board.clear()
        
        if robotFirst {
            first = first.next
        }
        robotFirst = !robotFirst
    }
    
    func didMove(_ move: Board.Move?) {
        self.move.value = move
        
        let status = board.status
        switch status {
        case .ongoing:
            whoseTurnText.value = yourTurn ? "your_turn".localized() : "opponent's_turn".localized()
            winnerAnnouncementText.value = nil
            winningCase.value = nil
        case .won(mark: let mark, case: let `case`):
            whoseTurnText.value = nil
            winnerAnnouncementText.value = mark == yourMark ? "you_win".localized() : "you_lose".localized()
            winningCase.value = `case`
        case .drawn:
            whoseTurnText.value = nil
            winnerAnnouncementText.value = "draw".localized()
            winningCase.value = nil
        }
        self.status.value = status
        
        if !yourTurn {
            if let position = robot.move() {
                let delay: TimeInterval = Double.random(in: 0.8...1.3)
                task = DispatchWorkItem { [weak self] in
                    guard let self else {
                        return
                    }
                    assert(self.board.turn != .none || self.robotFirst)
                    self.board.fill(move: Board.Move(position: position, mark: self.board.turn == .none ? self.first : self.board.turn))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task!)
            }
        }
    }
}
