import SwiftUI
import AppKit
import DesignSystem
import DofficeKit

extension SidebarView {
    var filteredProjectGroups: [SessionManager.ProjectGroup] {
        vm.filteredProjectGroups(manager: manager)
    }

    func matchesQuery(_ tab: TerminalTab, loweredQuery: String) -> Bool {
        vm.matchesQuery(tab, loweredQuery: loweredQuery)
    }

    func matchesFilter(_ tab: TerminalTab) -> Bool {
        vm.matchesFilter(tab)
    }

    func countForFilter(_ filter: SessionStatusFilter) -> Int {
        vm.countForFilter(filter, manager: manager)
    }

    func tabSortComparator(lhs: TerminalTab, rhs: TerminalTab) -> Bool {
        vm.tabSortComparator(lhs: lhs, rhs: rhs)
    }

    func compareGroups(_ lhs: SessionManager.ProjectGroup, _ rhs: SessionManager.ProjectGroup) -> Bool {
        vm.compareGroups(lhs, rhs)
    }
}
