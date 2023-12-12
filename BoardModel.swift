import Foundation

protocol BoardModelInput {
    @discardableResult
    func fill(move: Board.Move) -> Bool
    
    func clear()
}

protocol BoardModelOutput {
    var move: Observable<Board.Move?> { get }
    
    var allPositions: Set<Board.Position> { get }
    var winningCases: Set<Set<Board.Position>> { get }
    var turn: Board.Mark { get }
    var status: Board.Status { get }
    subscript(index: Int) -> [Board.Mark] { get }
    func positions(mark: Board.Mark) -> Set<Board.Position>
}

protocol BoardModel: BoardModelInput, BoardModelOutput { }

class MyBoardModel: BoardModel {
    let allPositions: Set<Board.Position> = [
        Board.Position(row: 0, column: 0),
        Board.Position(row: 0, column: 1),
        Board.Position(row: 0, column: 2),
        Board.Position(row: 1, column: 0),
        Board.Position(row: 1, column: 1),
        Board.Position(row: 1, column: 2),
        Board.Position(row: 2, column: 0),
        Board.Position(row: 2, column: 1),
        Board.Position(row: 2, column: 2)
    ]
    
    let winningCases: Set<Set<Board.Position>> = [
        Set([Board.Position(row: 0, column: 0), Board.Position(row: 0, column: 1), Board.Position(row: 0, column: 2)]),
        Set([Board.Position(row: 1, column: 0), Board.Position(row: 1, column: 1), Board.Position(row: 1, column: 2)]),
        Set([Board.Position(row: 2, column: 0), Board.Position(row: 2, column: 1), Board.Position(row: 2, column: 2)]),
        
        Set([Board.Position(row: 0, column: 0), Board.Position(row: 1, column: 0), Board.Position(row: 2, column: 0)]),
        Set([Board.Position(row: 0, column: 1), Board.Position(row: 1, column: 1), Board.Position(row: 2, column: 1)]),
        Set([Board.Position(row: 0, column: 2), Board.Position(row: 1, column: 2), Board.Position(row: 2, column: 2)]),
        
        Set([Board.Position(row: 0, column: 0), Board.Position(row: 1, column: 1), Board.Position(row: 2, column: 2)]),
        Set([Board.Position(row: 0, column: 2), Board.Position(row: 1, column: 1), Board.Position(row: 2, column: 0)])
    ]
    
    private(set) var turn: Board.Mark = .none
    
    @discardableResult
    func fill(move: Board.Move) -> Bool {
        precondition(move.mark != .none)
        
        if status != .ongoing {
            return false
        }
        
        if turn == .none {
            turn = move.mark
        }
        
        if self[move.position.row][move.position.column] != .none {
            return false
        }
        moves.append(move);
        return true
    }
    
    func clear() {
        moves.removeAll()
    }
    
    // TODO: Rewrite as subscript(Int, Int)
    subscript(index: Int) -> [Board.Mark] {
        precondition(0...2 ~= index)
        
        var row: [Board.Mark] = [.none, .none, .none]
        moves.filter({ $0.position.row == index }).forEach {
            assert($0.mark != .none)
            row[$0.position.column] = $0.mark
        }
        return row
    }
    
    private var moves: [Board.Move] = [] {
        didSet {
            turn = moves.isEmpty ? .none : turn.next
            move.value = moves.last
        }
    }
    
    var move: Observable<Board.Move?> = Observable(nil)
    
    var status: Board.Status {
        for mark in [Board.Mark.nought, Board.Mark.cross] {
            let positions = positions(mark: mark)
            if let `case` = winningCases.first(where: { positions.isSuperset(of: $0) }) {
                return .won(mark: mark, case: `case`)
            }
        }
        if moves.count == 9 {
            return .drawn
        }
        return .ongoing
    }
    
    func positions(mark: Board.Mark) -> Set<Board.Position> {
        switch mark {
        case .nought:
            return Set(moves.positions(marks: [mark]))
        case .cross:
            return Set(moves.positions(marks: [mark]))
        case .none:
            return allPositions.subtracting(Set(moves.positions()))
        }
    }
}
