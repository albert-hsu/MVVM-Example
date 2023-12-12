import Foundation

struct Board {
    enum Mark {
        case none
        case nought
        case cross
        
        var next: Mark {
            switch self {
            case .nought:
                return .cross
            case .cross:
                return .nought
            case .none:
                assertionFailure()
                return .none
            }
        }
    }
    
    struct Position: Hashable {
        let row: Int
        let column: Int
        
        init(row: Int, column: Int) {
            precondition(0...2 ~= row)
            precondition(0...2 ~= column)
            
            self.row = row
            self.column = column
        }
    }
    
    enum Status: Equatable {
        case ongoing
        case won(mark: Mark, case: Set<Position>)
        case drawn
    }
    
    struct Move {
        let position: Position
        let mark: Mark
        
        init(position: Position, mark: Mark) {
            precondition(mark != .none)
            
            self.position = position
            self.mark = mark
        }
    }
}

extension Array where Element == Board.Move {
    func positions(marks: [Board.Mark] = [.nought, .cross]) -> [Board.Position] {
        return self.filter({ marks.contains($0.mark) }).map({ $0.position })
    }
}
