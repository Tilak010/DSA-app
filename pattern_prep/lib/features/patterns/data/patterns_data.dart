import '../models/pattern_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Category constants (Categories A through K)
// ─────────────────────────────────────────────────────────────────────────────

final List<String> kPatternCategories = [
  'All',
  PatternCategories.arraysAndStrings,
  PatternCategories.searchingAndSorting,
  PatternCategories.linkedLists,
  PatternCategories.stacksAndQueues,
  PatternCategories.recursionAndBacktracking,
  PatternCategories.treesAndBst,
  PatternCategories.heaps,
  PatternCategories.graphs,
  PatternCategories.greedyAndIntervals,
  PatternCategories.dynamicProgramming,
  PatternCategories.otherImportantPatterns,
];

// ─────────────────────────────────────────────────────────────────────────────
// Pattern Detail Data
// ─────────────────────────────────────────────────────────────────────────────

final List<PatternDetail> kPatternDetails = [
  // ── A. Arrays and Strings: Two Pointers ─────────────────────────────────────
  PatternDetail(
    id: 'two_pointers',
    name: 'Two Pointers',
    category: PatternCategories.arraysAndStrings,
    quickIdea: 'Use two indices moving toward or past each other to narrow down pairs/bounds in O(n) without nested loops.',
    whenToUse: [
      'Searching pairs or triplets in sorted arrays that satisfy target sums or equations.',
      'Checking palindromes or symmetric sequence properties.',
      'In-place element removal, deduplication, or partitioning.',
      'Merging two sorted arrays without extra space.',
    ],
    recognitionClues: [
      '"Find a pair that sums to target"',
      'Array is already sorted (or can be sorted in O(n log n))',
      'Need to reduce an O(n²) brute force search to O(n)',
      'Subarray/segment boundary comparison from opposite ends',
    ],
    howItWorks:
        'Because the data structure is ordered (e.g. sorted), the sum or comparison value of extremes '
        'provides a monotonic direction: moving the left pointer inward strictly increases the sum, '
        'while moving the right pointer inward strictly decreases the sum. This guarantees we can '
        'eliminate candidate pairs in O(1) per step.',
    variations: [
      'Opposite Ends (Left starts at 0, Right starts at n-1)',
      'Same Direction / Reader-Writer (Fast moves ahead, Slow writes unique values)',
      'Simultaneous Pointers across Two Distinct Arrays',
    ],
    algorithmSteps: [
      'Sort array if allowed and not already sorted.',
      'Initialize left = 0, right = n - 1.',
      'While left < right:',
      '  Compute current metric (e.g., sum = arr[left] + arr[right]).',
      '  If sum matches target: record pair, advance left and decrement right.',
      '  If sum < target: advance left to increase sum.',
      '  If sum > target: decrement right to decrease sum.',
      'Skip duplicate adjacent values to avoid repeated answers.',
    ],
    timeComplexity: 'O(n) single pass (or O(n log n) if sorting is required)',
    spaceComplexity: 'O(1) auxiliary space',
    commonMistakes: [
      'Forgetting that opposite-end two pointers requires a sorted array.',
      'Using left <= right instead of left < right, which may pair an element with itself.',
      'Failing to skip duplicate values when unique combinations are requested.',
      'Off-by-one errors when advancing past duplicates.',
    ],
    edgeCases: [
      'Empty array or array of length < 2.',
      'Array contains negative numbers or all identical elements.',
      'Target sum cannot be formed by any pair.',
      'Integer overflow when adding two large values (use long long / 64-bit int).',
    ],
    relatedPatterns: ['fixed_sliding_window', 'variable_sliding_window', 'fast_slow_pointers', 'binary_search'],
    codeTemplates: [
      CodeTemplate(
        title: 'Two Pointers (Sorted Pair Sum)',
        description: 'Standard two-pointer search on a sorted sequence.',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: r'''#include <vector>
using namespace std;

// Returns 1-based or 0-based indices of the pair summing to target
vector<int> twoSumSorted(const vector<int>& nums, int target) {
    int left = 0;
    int right = static_cast<int>(nums.size()) - 1;

    while (left < right) {
        long long currentSum = static_cast<long long>(nums[left]) + nums[right];
        if (currentSum == target) {
            return {left, right}; // Found pair
        } else if (currentSum < target) {
            left++; // Need larger sum
        } else {
            right--; // Need smaller sum
        }
    }
    return {}; // No pair found
}''',
        pythonCode: r'''def two_sum_sorted(nums: list[int], target: int) -> list[int]:
    """Find 0-based indices of two numbers that sum to target in a sorted list."""
    left = 0
    right = len(nums) - 1

    while left < right:
        curr_sum = nums[left] + nums[right]
        if curr_sum == target:
            return [left, right]
        elif curr_sum < target:
            left += 1
        else:
            right -= 1

    return []''',
      ),
    ],
  ),

  // ── A. Arrays and Strings: Fixed-Size Sliding Window ───────────────────────
  PatternDetail(
    id: 'fixed_sliding_window',
    name: 'Fixed-Size Sliding Window',
    category: PatternCategories.arraysAndStrings,
    quickIdea: 'Maintain a window of exact size k by adding the incoming element and subtracting the outgoing element in O(1).',
    whenToUse: [
      'Calculating maximum, minimum, or average sum over contiguous subarrays of exact length k.',
      'Finding substrings of fixed length k matching specific anagram or frequency constraints.',
      'Moving average or rate-limiting windows.',
    ],
    recognitionClues: [
      '"Subarray of size k"',
      '"Contiguous subarray of length exactly k"',
      'Fixed window size given in problem statement',
      'Compute metric for every consecutive window of length k',
    ],
    howItWorks:
        'Instead of recalculating the window metric from scratch in O(k) for every position (leading to O(n·k)), '
        'we slide the window forward by 1 index: add arr[i] and remove arr[i - k]. This updates the state in O(1), '
        'achieving O(n) total time.',
    variations: [
      'Fixed Sum Window (running total)',
      'Fixed Frequency Map Window (anagram / permutation check of size k)',
      'Max/Min in Window (using Monotonic Deque)',
    ],
    algorithmSteps: [
      'Compute initial aggregate for the first k elements (indices 0 to k-1).',
      'Initialize bestResult with the initial window metric.',
      'Iterate i from k to n - 1:',
      '  Add incoming element arr[i] to window state.',
      '  Remove outgoing element arr[i - k] from window state.',
      '  Update bestResult with new window state.',
      'Return bestResult.',
    ],
    timeComplexity: 'O(n) where n is array length',
    spaceComplexity: 'O(1) auxiliary space (or O(alphabet) for frequency maps)',
    commonMistakes: [
      'Off-by-one errors with outgoing index (correct outgoing index is i - k).',
      'Not handling cases where array length n < k.',
      'Recomputing the full sum inside the loop instead of doing rolling updates.',
    ],
    edgeCases: [
      'Array length n < k (return 0 or handle invalid input).',
      'Window size k == 1 (trivially each element).',
      'Window size k == n (only 1 window possible).',
      'Negative numbers in sum computation.',
    ],
    relatedPatterns: ['variable_sliding_window', 'two_pointers', 'prefix_sum', 'monotonic_queue'],
    codeTemplates: [
      CodeTemplate(
        title: 'Fixed Sliding Window (Max Sum Subarray of Size K)',
        description: 'Standard rolling sum algorithm for fixed window of length k.',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: r'''#include <vector>
#include <algorithm>
using namespace std;

long long maxSubarraySumK(const vector<int>& nums, int k) {
    int n = static_cast<int>(nums.size());
    if (n < k || k <= 0) return 0;

    long long windowSum = 0;
    for (int i = 0; i < k; i++) {
        windowSum += nums[i];
    }

    long long maxSum = windowSum;
    for (int i = k; i < n; i++) {
        windowSum += nums[i] - nums[i - k]; // Slide window: +in, -out
        maxSum = max(maxSum, windowSum);
    }
    return maxSum;
}''',
        pythonCode: r'''def max_subarray_sum_k(nums: list[int], k: int) -> int:
    """Find maximum sum of any contiguous subarray of size k."""
    n = len(nums)
    if n < k or k <= 0:
        return 0

    window_sum = sum(nums[:k])
    max_sum = window_sum

    for i in range(k, n):
        window_sum += nums[i] - nums[i - k]  # Slide window
        if window_sum > max_sum:
            max_sum = window_sum

    return max_sum''',
      ),
    ],
  ),

  // ── A. Arrays and Strings: Variable-Size Sliding Window ─────────────────────
  PatternDetail(
    id: 'variable_sliding_window',
    name: 'Variable-Size Sliding Window',
    category: PatternCategories.arraysAndStrings,
    quickIdea: 'Expand right pointer to satisfy/grow a condition; shrink left pointer when violated (or to find minimum length).',
    whenToUse: [
      'Finding the longest subarray or substring with at most k distinct characters/zeros.',
      'Finding the shortest subarray with sum at least target (non-negative numbers).',
      'Substring search with character replacement constraints.',
    ],
    recognitionClues: [
      '"Longest substring without repeating characters"',
      '"Shortest subarray with sum >= target"',
      'Contiguous segment criteria with monotonic property',
      '"At most K distinct elements"',
    ],
    howItWorks:
        'Right pointer expands the candidate window step by step. If a constraint is violated, '
        'left pointer contracts the window until the condition is restored. Because both left and '
        'right pointers only move forward, total pointer advancements are at most 2n, giving O(n) time.',
    variations: [
      'Longest Valid Window (contract left only when condition is invalid)',
      'Shortest Valid Window (contract left while condition remains valid, tracking min length)',
      'Exact-K constraint = (AtMostK(K) - AtMostK(K - 1))',
    ],
    algorithmSteps: [
      'Initialize left = 0, state = empty (or 0), bestResult.',
      'For right = 0 to n - 1:',
      '  Include arr[right] into current window state.',
      '  While condition is violated (for max window) or condition is satisfied (for min window):',
      '    Update bestResult if looking for minimum valid window.',
      '    Remove arr[left] from window state.',
      '    left++.',
      '  Update bestResult if looking for maximum valid window.',
      'Return bestResult.',
    ],
    timeComplexity: 'O(n) where each element enters and leaves window at most once',
    spaceComplexity: 'O(k) where k is number of distinct elements stored in frequency map',
    commonMistakes: [
      'Applying this pattern to minimum sum when array contains negative numbers (requires prefix sum + deque).',
      'Forgetting to decrement frequency count or remove key when left pointer advances.',
      'Updating the answer before the window is in a strictly valid state.',
    ],
    edgeCases: [
      'Empty string or array of length 0.',
      'All characters/elements are unique.',
      'All characters/elements are identical.',
      'Target cannot be reached (return 0 or appropriate sentinel).',
    ],
    relatedPatterns: ['fixed_sliding_window', 'two_pointers', 'prefix_sum', 'hashing_frequency'],
    codeTemplates: [
      CodeTemplate(
        title: 'Variable Sliding Window (Shortest Subarray Sum >= Target)',
        description: 'Finds min length contiguous subarray with sum >= target (positive values).',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: r'''#include <vector>
#include <algorithm>
#include <climits>
using namespace std;

int minSubArrayLen(int target, const vector<int>& nums) {
    int n = static_cast<int>(nums.size());
    int minLen = INT_MAX;
    long long currentSum = 0;
    int left = 0;

    for (int right = 0; right < n; right++) {
        currentSum += nums[right];
        // Contract from left while valid
        while (currentSum >= target) {
            minLen = min(minLen, right - left + 1);
            currentSum -= nums[left];
            left++;
        }
    }
    return (minLen == INT_MAX) ? 0 : minLen;
}''',
        pythonCode: r'''def min_sub_array_len(target: int, nums: list[int]) -> int:
    """Find minimal length of a contiguous subarray whose sum >= target."""
    n = len(nums)
    min_len = float('inf')
    current_sum = 0
    left = 0

    for right in range(n):
        current_sum += nums[right]
        # Contract while condition holds
        while current_sum >= target:
            min_len = min(min_len, right - left + 1)
            current_sum -= nums[left]
            left += 1

    return 0 if min_len == float('inf') else min_len''',
      ),
    ],
  ),

  // ── A. Arrays and Strings: Prefix Sum ───────────────────────────────────────
  PatternDetail(
    id: 'prefix_sum',
    name: 'Prefix Sum',
    category: PatternCategories.arraysAndStrings,
    quickIdea: 'Precompute cumulative sums so any contiguous range sum [L, R] can be answered in O(1) via prefix[R+1] - prefix[L].',
    whenToUse: [
      'Multiple range sum queries on an immutable array.',
      'Finding count of subarrays whose sum equals k (using Prefix Sum + Hash Map).',
      '2D range sum queries in a matrix.',
      'Checking equilibrium index or balance points in an array.',
    ],
    recognitionClues: [
      '"Subarray sum equals K"',
      '"Range sum query"',
      'Multiple sum queries on subarray intervals',
      'Problems asking about differences between cumulative properties',
    ],
    howItWorks:
        'By storing the sum from index 0 to i in prefix[i+1], any range sum sum(L..R) is '
        'prefix[R+1] - prefix[L]. When combined with a frequency hash table storing past prefix sums, '
        'we can find subarrays with sum = k by checking if (currentPrefix - k) was observed previously.',
    variations: [
      '1D Prefix Sum (basic range queries)',
      'Prefix Sum + Hash Map (Subarray Sum Equals K in O(n))',
      '2D Matrix Prefix Sum (submatrix sums in O(1))',
      'Prefix Product / Prefix XOR',
    ],
    algorithmSteps: [
      'Create prefix array of size n + 1, with prefix[0] = 0.',
      'Fill prefix[i + 1] = prefix[i] + arr[i].',
      'To query range [L, R]: answer is prefix[R + 1] - prefix[L].',
      'For Subarray Sum = K:',
      '  Maintain running prefixSum and countMap with countMap[0] = 1.',
      '  For each x in arr: prefixSum += x; result += countMap[prefixSum - k]; countMap[prefixSum]++.',
    ],
    timeComplexity: 'O(n) precomputation, O(1) per range query',
    spaceComplexity: 'O(n) auxiliary space (or O(1) in-place)',
    commonMistakes: [
      'Forgetting to initialize countMap[0] = 1 when counting subarrays summing to k.',
      '1-indexed vs 0-indexed confusion (prefix[0] = 0 avoids special boundary checks for L = 0).',
      'Integer overflow on cumulative sum when array elements are large.',
    ],
    edgeCases: [
      'Array contains 0s and negative numbers.',
      'Target sum k is 0 or negative.',
      'Single element array.',
      'Entire array sums to target k.',
    ],
    relatedPatterns: ['two_pointers', 'difference_array', 'hashing_frequency', 'kadanes_algorithm'],
    codeTemplates: [
      CodeTemplate(
        title: 'Prefix Sum + Hash Map (Subarray Sum Equals K)',
        description: 'Count subarrays summing to k in O(n) time and O(n) space.',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(n)',
        cppCode: r'''#include <vector>
#include <unordered_map>
using namespace std;

int subarraySum(const vector<int>& nums, int k) {
    unordered_map<long long, int> prefixCounts;
    prefixCounts[0] = 1; // Base case: prefix sum of 0 appears once initially

    long long currentPrefix = 0;
    int totalCount = 0;

    for (int num : nums) {
        currentPrefix += num;
        // Check if there is a prefix such that currentPrefix - targetPrefix = k
        if (prefixCounts.find(currentPrefix - k) != prefixCounts.end()) {
            totalCount += prefixCounts[currentPrefix - k];
        }
        prefixCounts[currentPrefix]++;
    }
    return totalCount;
}''',
        pythonCode: r'''def subarray_sum(nums: list[int], k: int) -> int:
    """Return count of subarrays that sum to k using prefix sum + hash map."""
    prefix_counts = {0: 1}
    current_prefix = 0
    total_count = 0

    for num in nums:
        current_prefix += num
        # If (current_prefix - k) has been seen, add its occurrence count
        total_count += prefix_counts.get(current_prefix - k, 0)
        prefix_counts[current_prefix] = prefix_counts.get(current_prefix, 0) + 1

    return total_count''',
      ),
    ],
  ),

  // ── B. Searching and Sorting: Binary Search ─────────────────────────────────
  PatternDetail(
    id: 'binary_search',
    name: 'Binary Search',
    category: PatternCategories.searchingAndSorting,
    quickIdea: 'Halve the search space in each iteration by testing the midpoint against a monotonic condition in O(log n).',
    whenToUse: [
      'Searching for a value or insertion point in a sorted array.',
      'Finding lower bound (first index >= target) or upper bound (first index > target).',
      'Binary Search on Answer (finding min/max feasible value when feasibility is monotonic).',
      'Searching in rotated sorted array or finding peak elements.',
    ],
    recognitionClues: [
      'Array is sorted',
      '"Find minimum x such that condition(x) is true"',
      'Need better than O(n) time — typically O(log n)',
      '"Maximize the minimum" or "Minimize the maximum"',
    ],
    howItWorks:
        'Binary search operates on any search space that exhibits a monotonic boolean property: '
        'F F F ... F T T T ... T. By evaluating condition(mid), we can discard either the left half '
        'or right half, reducing the remaining search space by 50% each step.',
    variations: [
      'Exact Match (standard target search)',
      'Lower Bound / Bisect Left (first element >= target)',
      'Upper Bound / Bisect Right (first element > target)',
      'Binary Search on Answer / Predicate Search',
    ],
    algorithmSteps: [
      'Define search boundaries: low = minPossible, high = maxPossible.',
      'While low <= high (or low < high depending on template):',
      '  mid = low + (high - low) / 2 to avoid overflow.',
      '  If condition(mid) is satisfied:',
      '    Record mid as candidate answer, search better half.',
      '  Else:',
      '    Search opposite half.',
      'Return best recorded candidate.',
    ],
    timeComplexity: 'O(log n) where n is search space size',
    spaceComplexity: 'O(1) auxiliary space',
    commonMistakes: [
      'Integer overflow with (low + high) / 2 in C++ (always use low + (high - low) / 2).',
      'Infinite loops due to incorrect midpoint rounding when low + 1 == high.',
      'Returning index without verifying whether target was actually found.',
      'Not identifying the monotonic property in answer search problems.',
    ],
    edgeCases: [
      'Empty search space.',
      'Target smaller than smallest element or larger than largest element.',
      'Array with all duplicate elements.',
      'Array of length 1.',
    ],
    relatedPatterns: ['lower_upper_bound', 'binary_search_answer', 'two_pointers'],
    codeTemplates: [
      CodeTemplate(
        title: 'Binary Search (Lower Bound / First Index >= Target)',
        description: 'Finds first index in sorted array where nums[index] >= target.',
        timeComplexity: 'O(log n)',
        spaceComplexity: 'O(1)',
        cppCode: r'''#include <vector>
using namespace std;

int lowerBound(const vector<int>& nums, int target) {
    int low = 0;
    int high = static_cast<int>(nums.size()) - 1;
    int result = static_cast<int>(nums.size()); // Default: target is greater than all

    while (low <= high) {
        int mid = low + (high - low) / 2;
        if (nums[mid] >= target) {
            result = mid;       // Candidate found; try finding earlier index on left
            high = mid - 1;
        } else {
            low = mid + 1;      // Too small, must search right
        }
    }
    return result;
}''',
        pythonCode: r'''def lower_bound(nums: list[int], target: int) -> int:
    """Find first index where nums[index] >= target. Returns len(nums) if none."""
    low = 0
    high = len(nums) - 1
    result = len(nums)

    while low <= high:
        mid = low + (high - low) // 2
        if nums[mid] >= target:
            result = mid
            high = mid - 1  # Look for earlier occurrence on left
        else:
            low = mid + 1

    return result''',
      ),
    ],
  ),

  // ── C. Linked Lists: Fast and Slow Pointers ─────────────────────────────────
  PatternDetail(
    id: 'fast_slow_pointers',
    name: 'Fast and Slow Pointers',
    category: PatternCategories.linkedLists,
    quickIdea: 'Use two pointers moving at different speeds (1 step vs 2 steps) to find cycles or midpoints in O(1) space.',
    whenToUse: [
      'Detecting a cycle in a linked list or sequence (Floyd\'s Tortoise and Hare).',
      'Finding the start node of a linked list cycle.',
      'Finding the middle node of a linked list in one pass.',
      'Finding cycle in array jump problems or duplicate number detection.',
    ],
    recognitionClues: [
      '"Detect cycle in linked list"',
      '"Find the middle node of a linked list"',
      'Traverse linked list in single pass without knowing length in advance',
      'Constrained to O(1) auxiliary space on linked structure',
    ],
    howItWorks:
        'Slow pointer advances 1 node per iteration; fast pointer advances 2 nodes. '
        'If there is no cycle, fast reaches null in n/2 steps, leaving slow precisely at the middle. '
        'If a cycle exists, the distance between fast and slow decreases by 1 in each step inside the loop, '
        'guaranteeing they will meet inside the cycle.',
    variations: [
      'Middle of Linked List (single pass, no cycle)',
      'Floyd\'s Cycle Detection (boolean hasCycle)',
      'Find Cycle Start Node (reset slow to head after meeting, advance both by 1)',
      'Happy Number / Sequence cycle detection',
    ],
    algorithmSteps: [
      'Initialize slow = head, fast = head.',
      'While fast != null and fast.next != null:',
      '  slow = slow.next',
      '  fast = fast.next.next',
      '  If slow == fast: cycle detected!',
      'To find cycle entrance node:',
      '  Reset slow = head; keep fast at meeting point.',
      '  While slow != fast: slow = slow.next; fast = fast.next.',
      '  Return slow (the cycle entry node).',
    ],
    timeComplexity: 'O(n) linear traversal',
    spaceComplexity: 'O(1) space (no hash set required)',
    commonMistakes: [
      'Null pointer exception: forgetting to check both fast != null AND fast.next != null.',
      'For middle of linked list: confusing lower middle vs upper middle on even lengths.',
      'Not advancing slow and fast before checking equality in do-while situations.',
    ],
    edgeCases: [
      'Empty list (head == null).',
      'Single node list with no cycle (head.next == null).',
      'Single node list that points to itself.',
      'Two-node lists.',
    ],
    relatedPatterns: ['two_pointers', 'linked_list_reversal', 'dummy_node'],
    codeTemplates: [
      CodeTemplate(
        title: 'Floyd\'s Cycle Detection & Cycle Entry',
        description: 'Detects cycle and returns starting node of cycle, or nullptr if none.',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: r'''struct ListNode {
    int val;
    ListNode* next;
    ListNode(int x) : val(x), next(nullptr) {}
};

ListNode* detectCycle(ListNode* head) {
    if (!head || !head->next) return nullptr;

    ListNode* slow = head;
    ListNode* fast = head;

    // Step 1: Detect if a cycle exists
    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
        if (slow == fast) {
            // Step 2: Find the cycle start node
            ListNode* ptr1 = head;
            ListNode* ptr2 = slow;
            while (ptr1 != ptr2) {
                ptr1 = ptr1->next;
                ptr2 = ptr2->next;
            }
            return ptr1;
        }
    }
    return nullptr; // No cycle
}''',
        pythonCode: r'''class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def detect_cycle(head: ListNode | None) -> ListNode | None:
    """Detect cycle and return entrance node, or None if no cycle."""
    if not head or not head.next:
        return None

    slow = head
    fast = head

    # Phase 1: Detect cycle
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow == fast:
            # Phase 2: Find cycle start
            ptr1 = head
            ptr2 = slow
            while ptr1 != ptr2:
                ptr1 = ptr1.next
                ptr2 = ptr2.next
            return ptr1

    return None''',
      ),
    ],
  ),

  // ── D. Stacks and Queues: Monotonic Stack ───────────────────────────────────
  PatternDetail(
    id: 'monotonic_stack',
    name: 'Monotonic Stack',
    category: PatternCategories.stacksAndQueues,
    quickIdea: 'Maintain a stack whose elements are strictly increasing or decreasing to solve Next Greater/Smaller element in O(n).',
    whenToUse: [
      'Finding the Next Greater Element (NGE) or Previous Greater Element.',
      'Finding the Next Smaller Element or Previous Smaller Element.',
      'Largest Rectangle in Histogram.',
      'Trapping Rain Water.',
      'Daily Temperatures (days until warmer temperature).',
    ],
    recognitionClues: [
      '"Find the next greater/smaller element for every item"',
      '"Distance to the next higher value"',
      'Histogram bars, heights, or elevation boundaries',
      'Need O(n) instead of comparing each element with all subsequent elements',
    ],
    howItWorks:
        'The stack stores indices of elements in monotonic order. When a new element arr[i] arrives '
        'that violates the monotonicity, elements are popped from the stack. The incoming element arr[i] '
        'is precisely the "next greater/smaller" element for all the popped elements. '
        'Every element is pushed once and popped at most once, guaranteeing O(n) total operations.',
    variations: [
      'Monotonic Decreasing Stack (finds Next Greater Element)',
      'Monotonic Increasing Stack (finds Next Smaller Element)',
      'Circular Array NGE (run loop up to 2n - 1 using index modulo n)',
    ],
    algorithmSteps: [
      'Initialize an empty stack (stores indices).',
      'Create result array of size n filled with default value -1.',
      'For i from 0 to n - 1 (or 2n - 1 for circular):',
      '  While stack is not empty and arr[i] > arr[stack.top()]:',
      '    poppedIndex = stack.pop()',
      '    result[poppedIndex] = arr[i]',
      '  Push current index i onto stack.',
      'Return result.',
    ],
    timeComplexity: 'O(n) where each element is pushed and popped at most once',
    spaceComplexity: 'O(n) for stack storage',
    commonMistakes: [
      'Storing values instead of indices on the stack (storing indices allows computing distance and value).',
      'Confusing > vs >= when handling duplicate values.',
      'Forgetting to initialize unanswered elements with sentinel -1.',
    ],
    edgeCases: [
      'Array with all strictly decreasing elements (no next greater element exists).',
      'Array with all strictly increasing elements.',
      'Array with all identical elements.',
      'Single element array.',
    ],
    relatedPatterns: ['monotonic_queue', 'stack_basics', 'parentheses_matching'],
    codeTemplates: [
      CodeTemplate(
        title: 'Monotonic Decreasing Stack (Next Greater Element)',
        description: 'Finds the next greater element for each item in an array in O(n).',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(n)',
        cppCode: r'''#include <vector>
#include <stack>
using namespace std;

vector<int> nextGreaterElement(const vector<int>& nums) {
    int n = static_cast<int>(nums.size());
    vector<int> result(n, -1);
    stack<int> s; // Stores indices in decreasing order of value

    for (int i = 0; i < n; i++) {
        // While current element is greater than the top element of the stack
        while (!s.empty() && nums[i] > nums[s.top()]) {
            int prevIndex = s.top();
            s.pop();
            result[prevIndex] = nums[i];
        }
        s.push(i);
    }
    return result;
}''',
        pythonCode: r'''def next_greater_element(nums: list[int]) -> list[int]:
    """Find the next greater element for each item in nums, or -1 if none."""
    n = len(nums)
    result = [-1] * n
    stack = []  # Stores indices

    for i in range(n):
        while stack and nums[i] > nums[stack[-1]]:
            prev_idx = stack.pop()
            result[prev_idx] = nums[i]
        stack.append(i)

    return result''',
      ),
    ],
  ),

  // ── F. Trees and BST: Binary Tree DFS ───────────────────────────────────────
  PatternDetail(
    id: 'binary_tree_dfs',
    name: 'Binary Tree DFS',
    category: PatternCategories.treesAndBst,
    quickIdea: 'Traverse deep along paths using recursion/call stack in Preorder, Inorder, or Postorder in O(n).',
    whenToUse: [
      'Maximum / minimum depth of binary tree.',
      'Path sum, target root-to-leaf paths, and lowest common ancestor (LCA).',
      'Inverting or validating a binary search tree (Inorder produces sorted values).',
      'Subtree checks and diameter calculations.',
    ],
    recognitionClues: [
      '"Root to leaf path"',
      '"Depth or height of tree"',
      '"Check if tree is symmetric or balanced"',
      'Divide and conquer on left and right subtrees',
    ],
    howItWorks:
        'DFS explores as far as possible down each branch before backtracking. '
        'Preorder processes node before children (good for copying/serializing). '
        'Inorder processes left, root, right (sorted order for BST). '
        'Postorder processes children before node (essential for bottom-up property calculation like height/diameter).',
    variations: [
      'Top-Down DFS (pass accumulated path or parent state down to children)',
      'Bottom-Up DFS (return subtree metrics upward to assemble solution)',
      'Inorder Traversal for BST properties',
    ],
    algorithmSteps: [
      'Base Case: If root == null, return default value (0, true, null).',
      'Bottom-up: Recursively call dfs(root.left) and dfs(root.right).',
      'Combine: Compute result for current node using leftResult and rightResult.',
      'Return combined metric upward to caller.',
    ],
    timeComplexity: 'O(n) visiting each node exactly once',
    spaceComplexity: 'O(h) call stack where h is tree height (O(log n) balanced, O(n) worst-case skewed)',
    commonMistakes: [
      'Forgetting the base case (root == null), resulting in null dereference.',
      'For root-to-leaf paths: checking leaf condition incorrectly (must be root.left == null && root.right == null).',
      'Recomputing heights repeatedly causing O(n²) instead of single-pass bottom-up O(n).',
    ],
    edgeCases: [
      'Empty tree (root == null).',
      'Single node tree (both children null).',
      'Completely skewed tree (linked list behavior).',
      'Negative node values in path sum.',
    ],
    relatedPatterns: ['binary_tree_bfs', 'lowest_common_ancestor', 'diameter_tree_dp'],
    codeTemplates: [
      CodeTemplate(
        title: 'Binary Tree DFS (Max Depth & Bottom-Up Height)',
        description: 'Calculates maximum depth of a binary tree in O(n) bottom-up.',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(h)',
        cppCode: r'''#include <algorithm>
using namespace std;

struct TreeNode {
    int val;
    TreeNode* left;
    TreeNode* right;
    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}
};

int maxDepth(TreeNode* root) {
    if (!root) return 0; // Base case

    int leftHeight = maxDepth(root->left);
    int rightHeight = maxDepth(root->right);

    return 1 + max(leftHeight, rightHeight);
}''',
        pythonCode: r'''class TreeNode:
    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def max_depth(root: TreeNode | None) -> int:
    """Return maximum depth of binary tree using bottom-up DFS."""
    if not root:
        return 0

    left_height = max_depth(root.left)
    right_height = max_depth(root.right)

    return 1 + max(left_height, right_height)''',
      ),
    ],
  ),

  // ── F. Trees and BST: Binary Tree BFS ───────────────────────────────────────
  PatternDetail(
    id: 'binary_tree_bfs',
    name: 'Binary Tree BFS (Level Order)',
    category: PatternCategories.treesAndBst,
    quickIdea: 'Traverse level by level using a queue, tracking level size to process one entire depth at a time.',
    whenToUse: [
      'Level-order traversal (returning nodes grouped by depth).',
      'Finding the shortest path / minimum depth to a leaf.',
      'Connecting right pointers at each level (populating next right pointers).',
      'Zigzag level order or view of tree from right/left.',
    ],
    recognitionClues: [
      '"Level by level traversal"',
      '"Shortest path to nearest leaf"',
      '"Right side view of tree"',
      '"Nodes grouped by depth"',
    ],
    howItWorks:
        'A FIFO queue holds nodes waiting to be visited. At the start of each level iteration, '
        'the current queue length (levelSize) represents all nodes on the current level. '
        'A loop runs levelSize times, popping parents and pushing their children for the next level.',
    variations: [
      'Standard Level Order (2D list of values by level)',
      'Right/Left Side View (last or first node of each level)',
      'Shortest Path / Min Depth (stop as soon as first leaf node is dequeued)',
    ],
    algorithmSteps: [
      'If root == null, return empty list.',
      'Initialize queue q with root.',
      'While q is not empty:',
      '  levelSize = q.size()',
      '  Create currentLevel list.',
      '  For i from 0 to levelSize - 1:',
      '    node = q.pop()',
      '    Add node.val to currentLevel.',
      '    If node.left != null: q.push(node.left)',
      '    If node.right != null: q.push(node.right)',
      '  Append currentLevel to total result.',
      'Return result.',
    ],
    timeComplexity: 'O(n) visiting all n nodes',
    spaceComplexity: 'O(w) where w is maximum width of tree (up to n/2 in complete tree)',
    commonMistakes: [
      'Forgetting to freeze levelSize before the inner loop (queue grows as children are pushed).',
      'Checking queue emptiness inside the inner loop instead of the outer loop.',
      'Not guarding against null root.',
    ],
    edgeCases: [
      'Empty tree (root == null).',
      'Single node tree.',
      'Perfect binary tree (maximum width = (n+1)/2 nodes in queue).',
    ],
    relatedPatterns: ['binary_tree_dfs', 'graph_bfs', 'grid_traversal'],
    codeTemplates: [
      CodeTemplate(
        title: 'Binary Tree Level Order Traversal',
        description: 'Groups node values level by level using FIFO queue.',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(w)',
        cppCode: r'''#include <vector>
#include <queue>
using namespace std;

struct TreeNode {
    int val;
    TreeNode* left;
    TreeNode* right;
    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}
};

vector<vector<int>> levelOrder(TreeNode* root) {
    if (!root) return {};

    vector<vector<int>> result;
    queue<TreeNode*> q;
    q.push(root);

    while (!q.empty()) {
        int levelSize = static_cast<int>(q.size());
        vector<int> currentLevel;
        currentLevel.reserve(levelSize);

        for (int i = 0; i < levelSize; i++) {
            TreeNode* curr = q.front();
            q.pop();
            currentLevel.push_back(curr->val);

            if (curr->left) q.push(curr->left);
            if (curr->right) q.push(curr->right);
        }
        result.push_back(currentLevel);
    }
    return result;
}''',
        pythonCode: r'''from collections import deque

class TreeNode:
    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def level_order(root: TreeNode | None) -> list[list[int]]:
    """Return level-by-level list of node values."""
    if not root:
        return []

    result = []
    q = deque([root])

    while q:
        level_size = len(q)
        current_level = []

        for _ in range(level_size):
            node = q.popleft()
            current_level.append(node.val)
            if node.left:
                q.append(node.left)
            if node.right:
                q.append(node.right)

        result.append(current_level)

    return result''',
      ),
    ],
  ),

  // ── H. Graphs: Graph BFS ───────────────────────────────────────────────────
  PatternDetail(
    id: 'graph_bfs',
    name: 'Graph BFS',
    category: PatternCategories.graphs,
    quickIdea: 'Explore graph neighbor-by-neighbor using a queue and visited set to find shortest paths in unweighted graphs in O(V + E).',
    whenToUse: [
      'Shortest path in an unweighted graph or grid (e.g. minimum steps to reach target).',
      'Connected components detection.',
      'Multi-source BFS (e.g. rotting oranges, distance to nearest 0 in matrix).',
      'Word Ladder and state-space transitions.',
    ],
    recognitionClues: [
      '"Shortest path / minimum transformations in unweighted graph"',
      '"Fewest steps to reach target"',
      'Grid traversal with uniform 1-step weights',
      'Spreading or diffusion processes (fires, infection, rot)',
    ],
    howItWorks:
        'Because all edges have equal weight (1), exploring nodes in order of distance from start '
        'guarantees that the first time a node is reached, the path length to that node is optimal. '
        'A visited array/set ensures no node is processed more than once.',
    variations: [
      'Single-Source Shortest Path',
      'Multi-Source BFS (push all sources into queue simultaneously at step 0)',
      '0-1 BFS using Deque (edges with weight 0 or 1)',
    ],
    algorithmSteps: [
      'Initialize queue q and visited set/boolean array.',
      'Push source node to q, mark source as visited, distance = 0.',
      'While q is not empty:',
      '  Pop current node u.',
      '  If u == target: return distance.',
      '  For each neighbor v of u:',
      '    If v is not visited:',
      '      Mark v as visited.',
      '      Push v to q with distance + 1.',
      'If target unreachable, return -1.',
    ],
    timeComplexity: 'O(V + E) where V is vertices and E is edges',
    spaceComplexity: 'O(V) for queue and visited set',
    commonMistakes: [
      'Marking node as visited when popping from queue rather than when pushing (causes exponential duplicates in queue!).',
      'Applying standard BFS to graphs with variable edge weights (requires Dijkstra).',
      'Not validating grid boundaries before checking visited status.',
    ],
    edgeCases: [
      'Source is already target (return 0 steps).',
      'Disconnected graph where target is completely unreachable.',
      'Graph with cycles (handled cleanly by visited check).',
    ],
    relatedPatterns: ['graph_dfs', 'binary_tree_bfs', 'grid_traversal', 'shortest_paths'],
    codeTemplates: [
      CodeTemplate(
        title: 'Graph BFS (Shortest Path in Unweighted Graph)',
        description: 'Finds shortest path distance from start to target in unweighted graph.',
        timeComplexity: 'O(V + E)',
        spaceComplexity: 'O(V)',
        cppCode: r'''#include <vector>
#include <queue>
using namespace std;

int shortestPathBFS(int n, const vector<vector<int>>& adj, int start, int target) {
    if (start == target) return 0;

    vector<bool> visited(n, false);
    queue<pair<int, int>> q; // {node, distance}

    q.push({start, 0});
    visited[start] = true;

    while (!q.empty()) {
        auto [u, dist] = q.front();
        q.pop();

        for (int v : adj[u]) {
            if (v == target) return dist + 1; // Reached target
            if (!visited[v]) {
                visited[v] = true; // Mark visited when pushing!
                q.push({v, dist + 1});
            }
        }
    }
    return -1; // Unreachable
}''',
        pythonCode: r'''from collections import deque

def shortest_path_bfs(n: int, adj: list[list[int]], start: int, target: int) -> int:
    """Find shortest path from start to target in an unweighted graph."""
    if start == target:
        return 0

    visited = [False] * n
    q = deque([(start, 0)])
    visited[start] = True

    while q:
        u, dist = q.popleft()
        for v in adj[u]:
            if v == target:
                return dist + 1
            if not visited[v]:
                visited[v] = True  # Mark when enqueuing
                q.append((v, dist + 1))

    return -1''',
      ),
    ],
  ),

  // ── H. Graphs: Graph DFS ───────────────────────────────────────────────────
  PatternDetail(
    id: 'graph_dfs',
    name: 'Graph DFS',
    category: PatternCategories.graphs,
    quickIdea: 'Traverse deep into a graph branch recursively to detect cycles, components, or topological orders in O(V + E).',
    whenToUse: [
      'Finding all connected components in an undirected graph.',
      'Cycle detection in directed and undirected graphs.',
      'Topological sorting (postorder reversal in DAG).',
      'Flood fill and island counting in 2D grids.',
      'Bipartite graph testing / 2-coloring.',
    ],
    recognitionClues: [
      '"Number of islands" or "connected components"',
      '"Detect cycle in directed dependencies"',
      '"Course schedule prerequisite order"',
      'Exhaustive path search or reachability check',
    ],
    howItWorks:
        'DFS explores as deep as possible along each branch before backtracking. '
        'For cycle detection in directed graphs, a 3-color state system is used: '
        '0 = unvisited, 1 = visiting (currently on call stack), 2 = visited (completed). '
        'An edge pointing to a node currently in state 1 represents a back-edge (cycle).',
    variations: [
      'Connected Components (loop over all vertices, trigger DFS on unvisited)',
      'Cycle Detection in Directed Graphs (3-color state array)',
      'Topological Sort (Tarjan / postorder reversal)',
    ],
    algorithmSteps: [
      'Create visited boolean array or state array of size V.',
      'To count components: iterate i from 0 to V - 1; if !visited[i]: dfs(i), components++.',
      'dfs(u):',
      '  Mark visited[u] = true.',
      '  For each neighbor v of u:',
      '    If !visited[v]: dfs(v).',
    ],
    timeComplexity: 'O(V + E) linear in graph size',
    spaceComplexity: 'O(V) recursion call stack depth and visited array',
    commonMistakes: [
      'Stack overflow on large deep graphs (exceeding default recursion limits).',
      'Using a simple boolean visited array for directed cycle detection (requires 3-state coloring).',
      'Forgetting that graphs may be disconnected (must loop over all 0..V-1 nodes).',
    ],
    edgeCases: [
      'Graph with no edges (V isolated components).',
      'Graph with self-loops or multi-edges.',
      'Directed graph with back-edges vs cross-edges.',
    ],
    relatedPatterns: ['graph_bfs', 'topological_sorting', 'connected_components', 'union_find'],
    codeTemplates: [
      CodeTemplate(
        title: 'Graph DFS (Connected Components Count)',
        description: 'Counts independent connected components in an undirected graph.',
        timeComplexity: 'O(V + E)',
        spaceComplexity: 'O(V)',
        cppCode: r'''#include <vector>
using namespace std;

void dfs(int u, const vector<vector<int>>& adj, vector<bool>& visited) {
    visited[u] = true;
    for (int v : adj[u]) {
        if (!visited[v]) {
            dfs(v, adj, visited);
        }
    }
}

int countComponents(int n, const vector<vector<int>>& adj) {
    vector<bool> visited(n, false);
    int components = 0;

    for (int i = 0; i < n; i++) {
        if (!visited[i]) {
            components++;
            dfs(i, adj, visited);
        }
    }
    return components;
}''',
        pythonCode: r'''def count_components(n: int, adj: list[list[int]]) -> int:
    """Count number of connected components in an undirected graph."""
    visited = [False] * n
    components = 0

    def dfs(u: int) -> None:
        visited[u] = True
        for v in adj[u]:
            if not visited[v]:
                dfs(v)

    for i in range(n):
        if not visited[i]:
            components += 1
            dfs(i)

    return components''',
      ),
    ],
  ),

  // ── E. Recursion and Backtracking: Backtracking ─────────────────────────────
  PatternDetail(
    id: 'backtracking',
    name: 'Backtracking',
    category: PatternCategories.recursionAndBacktracking,
    quickIdea: 'Build solution incrementally; abandon (prune) candidates as soon as they violate constraints.',
    whenToUse: [
      'Generating all Subsets, Permutations, or Combinations.',
      'Constraint satisfaction problems (N-Queens, Sudoku solver, Crosswords).',
      'Partitioning problems (Palindrome Partitioning).',
      'Word Search on a grid.',
    ],
    recognitionClues: [
      '"Generate all possible valid combinations/permutations"',
      '"Find all subsets"',
      'Constraints n are small (e.g. n <= 16, 20)',
      'Need to undo decisions after recursive exploration',
    ],
    howItWorks:
        'Backtracking builds candidate solutions step by step through a decision tree. '
        'At each step, we: (1) Make a choice (add to path), (2) Recurse to next step, '
        '(3) Undo choice (backtrack / remove from path). Pruning conditions prune invalid branches early.',
    variations: [
      'Subsets / Power Set (choose or skip each element, or start from index i)',
      'Combinations of Size K (terminate when path length == k)',
      'Permutations (use a visited boolean array or swap elements in-place)',
    ],
    algorithmSteps: [
      'Define backtrack(startIndex, currentPath):',
      '  If base condition met: save copy of currentPath to results, return.',
      '  For i from startIndex to n - 1:',
      '    If candidate arr[i] invalid: continue (PRUNE).',
      '    Make choice: currentPath.push(arr[i]).',
      '    Recurse: backtrack(i + 1, currentPath).',
      '    Undo choice: currentPath.pop().',
    ],
    timeComplexity: 'O(2ⁿ) for subsets, O(n!) for permutations',
    spaceComplexity: 'O(n) recursion call stack and path storage',
    commonMistakes: [
      'Forgetting to make a deep copy of currentPath before pushing into the results list in Python/C++.',
      'Forgetting to undo the choice (pop) after the recursive call returns.',
      'Not handling duplicates properly (sort first, then if (i > start && arr[i] == arr[i-1]) continue).',
    ],
    edgeCases: [
      'Empty input array (produces single empty subset [[]]).',
      'Input contains duplicate values.',
      'Constraint k == 0 or k == n.',
    ],
    relatedPatterns: ['recursion_basics', 'subsets', 'permutations', 'pruning_techniques'],
    codeTemplates: [
      CodeTemplate(
        title: 'Backtracking (Subsets / Combinations)',
        description: 'Generates all subsets (power set) of unique integers.',
        timeComplexity: 'O(n · 2ⁿ)',
        spaceComplexity: 'O(n)',
        cppCode: r'''#include <vector>
using namespace std;

void backtrackSubsets(int start, const vector<int>& nums, vector<int>& current, vector<vector<int>>& result) {
    result.push_back(current); // Every state is a valid subset

    for (int i = start; i < static_cast<int>(nums.size()); i++) {
        current.push_back(nums[i]);            // 1. Choose
        backtrackSubsets(i + 1, nums, current, result); // 2. Explore
        current.pop_back();                     // 3. Backtrack
    }
}

vector<vector<int>> subsets(const vector<int>& nums) {
    vector<vector<int>> result;
    vector<int> current;
    backtrackSubsets(0, nums, current, result);
    return result;
}''',
        pythonCode: r'''def subsets(nums: list[int]) -> list[list[int]]:
    """Generate all subsets (power set) using backtracking."""
    result = []
    current = []

    def backtrack(start: int) -> None:
        result.append(list(current))  # Record snapshot of current path

        for i in range(start, len(nums)):
            current.append(nums[i])   # 1. Choose
            backtrack(i + 1)          # 2. Explore
            current.pop()             # 3. Backtrack

    backtrack(0)
    return result''',
      ),
    ],
  ),

  // ── I. Greedy and Intervals: Greedy ─────────────────────────────────────────
  PatternDetail(
    id: 'greedy',
    name: 'Greedy',
    category: PatternCategories.greedyAndIntervals,
    quickIdea: 'Make the locally optimal choice at each step hoping it yields the globally optimal solution in O(n log n).',
    whenToUse: [
      'Interval scheduling (meeting rooms, non-overlapping intervals).',
      'Gas station circular tour.',
      'Jump game (reachable boundaries).',
      'Huffman coding and fractional knapsack.',
    ],
    recognitionClues: [
      '"Find maximum non-overlapping intervals"',
      '"Minimum arrows to burst balloons"',
      'Locally optimal decision does not restrict future choices',
      'Sorting by start time or end time reveals obvious step-by-step choice',
    ],
    howItWorks:
        'Greedy algorithms work when the problem possesses the Greedy-Choice Property and '
        'Optimal Substructure: making the best choice at the present moment leaves a subproblem '
        'of the exact same structure without needing to backtrack or explore alternative choices.',
    variations: [
      'Interval Scheduling (sort by finish time to maximize count)',
      'Interval Merging (sort by start time to combine overlapping ranges)',
      'Exchange Argument Proofs',
    ],
    algorithmSteps: [
      'Sort intervals by end time (to maximize count) or start time (to merge).',
      'Initialize currentEnd with end time of first interval.',
      'For each subsequent interval [start, end]:',
      '  If start >= currentEnd: compatible! Include it, update currentEnd = end.',
      '  Else: overlapping conflict! Skip or drop.',
      'Return count or merged intervals list.',
    ],
    timeComplexity: 'O(n log n) dominated by initial sorting step',
    spaceComplexity: 'O(1) auxiliary (or O(n) for output array)',
    commonMistakes: [
      'Applying greedy to problems where local choices hurt future possibilities (e.g. 0/1 Knapsack, Coin Change with non-canonical coins).',
      'Sorting by start time when problem requires sorting by end time (or vice versa).',
      'Strict inequality vs non-strict inequality on boundary overlap.',
    ],
    edgeCases: [
      'Empty list or single interval.',
      'All intervals completely overlap.',
      'No intervals overlap at all.',
      'Intervals touch at single point [1, 2] and [2, 3].',
    ],
    relatedPatterns: ['merge_intervals', 'interval_scheduling', 'activity_selection'],
    codeTemplates: [
      CodeTemplate(
        title: 'Greedy Interval Scheduling (Non-overlapping Intervals)',
        description: 'Finds maximum number of non-overlapping intervals by sorting by end time.',
        timeComplexity: 'O(n log n)',
        spaceComplexity: 'O(1)',
        cppCode: r'''#include <vector>
#include <algorithm>
using namespace std;

// Returns count of maximum compatible intervals
int maxNonOverlappingIntervals(vector<vector<int>>& intervals) {
    if (intervals.empty()) return 0;

    // Sort by finish time ascending
    sort(intervals.begin(), intervals.end(), [](const vector<int>& a, const vector<int>& b) {
        return a[1] < b[1];
    });

    int count = 1;
    int lastEnd = intervals[0][1];

    for (size_t i = 1; i < intervals.size(); i++) {
        if (intervals[i][0] >= lastEnd) {
            count++;
            lastEnd = intervals[i][1];
        }
    }
    return count;
}''',
        pythonCode: r'''def max_non_overlapping_intervals(intervals: list[list[int]]) -> int:
    """Return maximum number of mutually compatible intervals."""
    if not intervals:
        return 0

    # Sort intervals by end time
    intervals.sort(key=lambda x: x[1])

    count = 1
    last_end = intervals[0][1]

    for start, end in intervals[1:]:
        if start >= last_end:
            count += 1
            last_end = end

    return count''',
      ),
    ],
  ),

  // ── J. Dynamic Programming: 1D DP ──────────────────────────────────────────
  PatternDetail(
    id: 'one_dimensional_dp',
    name: 'One-Dimensional Dynamic Programming',
    category: PatternCategories.dynamicProgramming,
    quickIdea: 'Solve linear subproblems where state depends on previous k states (dp[i] = f(dp[i-1], dp[i-2], ...)) in O(n).',
    whenToUse: [
      'Climbing stairs / Fibonacci variations.',
      'House Robber (take or skip element).',
      'Coin Change (minimum coins to make amount).',
      'Word Break.',
      'Longest Increasing Subsequence (O(n²) basic, O(n log n) with binary search).',
    ],
    recognitionClues: [
      '"Find the maximum / minimum cost / ways to reach index i"',
      'Optimal substructure: state at step i depends only on previous steps',
      'Subproblems overlap significantly',
      'Choices at step i are discrete (e.g. Rob vs Skip, Take coin vs Skip coin)',
    ],
    howItWorks:
        '1D DP decomposes a linear decision process. By defining dp[i] as the optimal value '
        'achievable using the prefix of the input up to index i, we can compute dp[i] from earlier '
        'precomputed states without redundant recomputations. Often space can be optimized to O(1) '
        'if dp[i] depends only on the last 1 or 2 states.',
    variations: [
      'Take or Skip (House Robber: dp[i] = max(dp[i-1], dp[i-2] + nums[i]))',
      'Min/Max Cost across Choices (Coin Change: dp[i] = min(dp[i - coin] + 1))',
      'Total Number of Ways (dp[i] = sum(dp[i - step]))',
    ],
    algorithmSteps: [
      'Define State: dp[i] = max loot achievable from houses 0 to i.',
      'Base Cases: dp[0] = nums[0], dp[1] = max(nums[0], nums[1]).',
      'Transition: dp[i] = max(dp[i-1], dp[i-2] + nums[i]).',
      'Space Optimization: Only keep prev1 and prev2 instead of full array.',
      'Return result.',
    ],
    timeComplexity: 'O(n) single pass',
    spaceComplexity: 'O(1) with rolling variables (or O(n) array)',
    commonMistakes: [
      'Incorrect base cases leading to index out of bounds on n = 1 or n = 2.',
      'Not initializing min-DP arrays with infinity (or max-DP with 0 / -infinity).',
      'Confusing 1-indexed DP array with 0-indexed input array.',
    ],
    edgeCases: [
      'Array length n == 0 or n == 1.',
      'All values 0 or negative.',
      'Amount 0 in coin change problems.',
    ],
    relatedPatterns: ['two_dimensional_dp', 'memoization', 'tabulation', 'space_optimization'],
    codeTemplates: [
      CodeTemplate(
        title: '1D DP (House Robber — Take or Skip)',
        description: 'Maximize sum without taking adjacent elements in O(n) time and O(1) space.',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: r'''#include <vector>
#include <algorithm>
using namespace std;

int rob(const vector<int>& nums) {
    int n = static_cast<int>(nums.size());
    if (n == 0) return 0;
    if (n == 1) return nums[0];

    int prev2 = nums[0];
    int prev1 = max(nums[0], nums[1]);

    for (int i = 2; i < n; i++) {
        int current = max(prev1, prev2 + nums[i]);
        prev2 = prev1;
        prev1 = current;
    }
    return prev1;
}''',
        pythonCode: r'''def rob(nums: list[int]) -> int:
    """Find maximum amount without robbing two adjacent houses in O(1) space."""
    if not nums:
        return 0
    if len(nums) == 1:
        return nums[0]

    prev2 = nums[0]
    prev1 = max(nums[0], nums[1])

    for i in range(2, len(nums)):
        current = max(prev1, prev2 + nums[i])
        prev2 = prev1
        prev1 = current

    return prev1''',
      ),
    ],
  ),

  // ── J. Dynamic Programming: 2D DP ──────────────────────────────────────────
  PatternDetail(
    id: 'two_dimensional_dp',
    name: 'Two-Dimensional Dynamic Programming',
    category: PatternCategories.dynamicProgramming,
    quickIdea: 'Use a 2D table dp[i][j] where states depend on two changing variables (e.g. two strings, grid cells, or items & capacity).',
    whenToUse: [
      'Longest Common Subsequence (LCS).',
      'Edit Distance (Levenshtein Distance).',
      '0/1 Knapsack Problem (items vs capacity).',
      'Grid paths with obstacles or minimum path sum.',
      'Regular Expression / Wildcard Matching.',
    ],
    recognitionClues: [
      '"Compare two strings / find longest common subsequence"',
      '"Minimum edit distance / transformations"',
      '"Knapsack with weight and value constraints"',
      'State requires two indices (i, j) to uniquely identify subproblem',
    ],
    howItWorks:
        'In 2D DP, state dp[i][j] represents the subproblem solution for prefixes s1[0..i-1] '
        'and s2[0..j-1]. Transitions come from adjacent cells: dp[i-1][j] (delete), dp[i][j-1] (insert), '
        'or dp[i-1][j-1] (match/replace). Space can often be optimized from O(m·n) to O(n) using '
        'two rows.',
    variations: [
      'Two Strings Matching (LCS, Edit Distance)',
      '0/1 Knapsack (items vs capacity)',
      'Grid DP (dp[r][c] = cost + min(dp[r-1][c], dp[r][c-1]))',
    ],
    algorithmSteps: [
      'Initialize dp array of dimensions (m + 1) × (n + 1).',
      'Base cases: dp[0][j] and dp[i][0] based on empty string/prefix semantics.',
      'Nested loops: for i from 1 to m, for j from 1 to n:',
      '  If s1[i-1] == s2[j-1]: dp[i][j] = 1 + dp[i-1][j-1]',
      '  Else: dp[i][j] = max(dp[i-1][j], dp[i][j-1])',
      'Return dp[m][n].',
    ],
    timeComplexity: 'O(m · n) filling an m × n grid',
    spaceComplexity: 'O(m · n) table (reducible to O(min(m, n)) space)',
    commonMistakes: [
      'Off-by-one errors mapping between 1-indexed DP table and 0-indexed string characters.',
      'Incorrect initialization of base row/column in Edit Distance (must be 0, 1, 2, ...).',
      'Inner loop direction in 0/1 Knapsack space optimization (must iterate backward!).',
    ],
    edgeCases: [
      'One or both strings are empty.',
      'Strings are completely identical.',
      'Strings share no characters in common.',
    ],
    relatedPatterns: ['one_dimensional_dp', 'knapsack', 'subsequence_dp', 'string_dp'],
    codeTemplates: [
      CodeTemplate(
        title: '2D DP (Longest Common Subsequence)',
        description: 'Computes length of longest common subsequence between two strings.',
        timeComplexity: 'O(m · n)',
        spaceComplexity: 'O(m · n)',
        cppCode: r'''#include <string>
#include <vector>
#include <algorithm>
using namespace std;

int longestCommonSubsequence(const string& text1, const string& text2) {
    int m = static_cast<int>(text1.size());
    int n = static_cast<int>(text2.size());
    vector<vector<int>> dp(m + 1, vector<int>(n + 1, 0));

    for (int i = 1; i <= m; i++) {
        for (int j = 1; j <= n; j++) {
            if (text1[i - 1] == text2[j - 1]) {
                dp[i][j] = 1 + dp[i - 1][j - 1]; // Character match
            } else {
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]); // Skip from text1 or text2
            }
        }
    }
    return dp[m][n];
}''',
        pythonCode: r'''def longest_common_subsequence(text1: str, text2: str) -> int:
    """Return length of LCS of two strings using 2D DP."""
    m, n = len(text1), len(text2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]

    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if text1[i - 1] == text2[j - 1]:
                dp[i][j] = 1 + dp[i - 1][j - 1]
            else:
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])

    return dp[m][n]''',
      ),
    ],
  ),

  // ── G. Heaps: Top-K Elements ───────────────────────────────────────────────
  PatternDetail(
    id: 'top_k_heap',
    name: 'Top-K Using a Heap',
    category: PatternCategories.heaps,
    quickIdea: 'Maintain a Min-Heap of size k to find the k largest elements in O(n log k) instead of O(n log n) sorting.',
    whenToUse: [
      'Finding the Kth Largest / Smallest element in an unsorted stream or array.',
      'Top K Frequent Elements in an array.',
      'K Closest Points to Origin.',
      'Sorting a nearly sorted (k-sorted) array in O(n log k).',
    ],
    recognitionClues: [
      '"Find the K largest / K smallest elements"',
      '"Top K frequent words / numbers"',
      'Unbounded or streaming input data where sorting is impossible',
      'Need O(n log k) performance where k << n',
    ],
    howItWorks:
        'To find the k LARGEST elements, maintain a MIN-HEAP of size k. '
        'For each element: push to heap; if heap.size() > k, pop the minimum element. '
        'After processing all n elements, the smallest elements have been discarded, '
        'and the heap root holds the kth largest element. Time is O(n log k) with O(k) memory.',
    variations: [
      'K Largest Elements (use Min-Heap of size k)',
      'K Smallest Elements (use Max-Heap of size k)',
      'Top K Frequent (Frequency Map + Min-Heap ordered by frequency)',
    ],
    algorithmSteps: [
      'Initialize Min-Heap.',
      'For each element in the input list:',
      '  Push element onto Min-Heap.',
      '  If heap size > k: pop min element.',
      'The heap root (or all elements remaining in heap) is the answer.',
      'Return heap root (kth largest) or all k heap elements.',
    ],
    timeComplexity: 'O(n log k) where k is number of items to track',
    spaceComplexity: 'O(k) auxiliary memory in heap',
    commonMistakes: [
      'Using a Max-Heap instead of a Min-Heap for k largest (a Max-Heap of all n elements takes O(n log n) to pop k times).',
      'Forgetting that default std::priority_queue in C++ is a MAX-heap (use greater<> for min-heap).',
      'Python heapq is min-heap by default; negate values for max-heap.',
    ],
    edgeCases: [
      'k == 1 (simple linear min/max scan in O(n)).',
      'k == n (equivalent to sorting entire array).',
      'Array contains duplicates.',
    ],
    relatedPatterns: ['kth_largest_smallest', 'two_heaps', 'priority_queue_patterns'],
    codeTemplates: [
      CodeTemplate(
        title: 'Top-K Heap (Kth Largest Element)',
        description: 'Finds kth largest element using a min-heap of size k in O(n log k).',
        timeComplexity: 'O(n log k)',
        spaceComplexity: 'O(k)',
        cppCode: r'''#include <vector>
#include <queue>
using namespace std;

int findKthLargest(const vector<int>& nums, int k) {
    // Min-heap storing top k largest elements seen so far
    priority_queue<int, vector<int>, greater<int>> minHeap;

    for (int num : nums) {
        minHeap.push(num);
        if (static_cast<int>(minHeap.size()) > k) {
            minHeap.pop(); // Evict smallest among the k+1 elements
        }
    }
    return minHeap.top(); // Root is the kth largest
}''',
        pythonCode: r'''import heapq

def find_kth_largest(nums: list[int], k: int) -> int:
    """Find kth largest element using min-heap of size k in O(n log k)."""
    min_heap = []

    for num in nums:
        heapq.heappush(min_heap, num)
        if len(min_heap) > k:
            heapq.heappop(min_heap)  # Evict smallest

    return min_heap[0]''',
      ),
    ],
  ),

  // ── H. Graphs: Union-Find (Disjoint Set Union) ──────────────────────────────
  PatternDetail(
    id: 'union_find',
    name: 'Union-Find (Disjoint Set Union)',
    category: PatternCategories.graphs,
    quickIdea: 'Maintain dynamic partitions of elements into disjoint sets with near O(1) find and union operations.',
    whenToUse: [
      'Dynamic connectivity queries (are nodes u and v connected?).',
      'Cycle detection in undirected graphs (if find(u) == find(v), adding edge creates cycle).',
      'Kruskal\'s Minimum Spanning Tree algorithm.',
      'Number of connected components as edges are added dynamically.',
      'Redundant connection identification.',
    ],
    recognitionClues: [
      '"Are these two elements in the same set / component?"',
      '"Detect cycle while building graph edge by edge"',
      '"Merge groups / accounts merge"',
      'Kruskal\'s algorithm for Minimum Spanning Tree',
    ],
    howItWorks:
        'Each set is represented by a tree where the root is the set representative. '
        'Path Compression flattens the tree during find(), pointing each node directly to root. '
        'Union by Rank/Size attaches the shorter tree under the taller tree root. '
        'Together, operations run in nearly O(1) amortized time (Ackermann inverse α(n) ≤ 4).',
    variations: [
      'Standard Disjoint Set with Path Compression and Rank',
      'Weighted / Size-tracking Union-Find (tracking component sizes)',
      'Union-Find with rollback / persistence',
    ],
    algorithmSteps: [
      'Initialize parent[i] = i and rank[i] = 0 for all i.',
      'find(u): If parent[u] != u: parent[u] = find(parent[u]) (path compression). Return parent[u].',
      'unionSets(u, v):',
      '  rootU = find(u), rootV = find(v).',
      '  If rootU == rootV: already connected (cycle detected!). Return false.',
      '  Attach smaller rank root to larger rank root. Return true.',
    ],
    timeComplexity: 'O(α(n)) ≈ O(1) amortized per operation',
    spaceComplexity: 'O(n) for parent and rank arrays',
    commonMistakes: [
      'Forgetting path compression (parent[u] = find(parent[u])) degrades tree into linked list O(n).',
      'Comparing parent[u] == parent[v] instead of find(u) == find(v).',
      'Not maintaining component count decrement when union succeeds.',
    ],
    edgeCases: [
      'Single node / 0 edges.',
      'Graph is a single giant component.',
      'Adding edge between already connected components (cycle).',
    ],
    relatedPatterns: ['connected_components', 'kruskals_mst', 'graph_bfs', 'graph_dfs'],
    codeTemplates: [
      CodeTemplate(
        title: 'Union-Find (Path Compression & Rank)',
        description: 'Complete Disjoint Set Union class supporting near O(1) find and union.',
        timeComplexity: 'O(α(n)) ≈ O(1)',
        spaceComplexity: 'O(n)',
        cppCode: r'''#include <vector>
#include <numeric>
using namespace std;

class UnionFind {
private:
    vector<int> parent;
    vector<int> rank;
    int components;

public:
    UnionFind(int n) : parent(n), rank(n, 0), components(n) {
        iota(parent.begin(), parent.end(), 0); // parent[i] = i
    }

    int find(int u) {
        if (parent[u] != u) {
            parent[u] = find(parent[u]); // Path compression
        }
        return parent[u];
    }

    bool unionSets(int u, int v) {
        int rootU = find(u);
        int rootV = find(v);
        if (rootU == rootV) return false; // Already in same set (cycle)

        // Union by rank
        if (rank[rootU] < rank[rootV]) {
            parent[rootU] = rootV;
        } else if (rank[rootU] > rank[rootV]) {
            parent[rootV] = rootU;
        } else {
            parent[rootV] = rootU;
            rank[rootU]++;
        }
        components--;
        return true;
    }

    int getComponentCount() const { return components; }
};''',
        pythonCode: r'''class UnionFind:
    """Disjoint Set Union with Path Compression and Union by Rank."""
    def __init__(self, n: int):
        self.parent = list(range(n))
        self.rank = [0] * n
        self.components = n

    def find(self, u: int) -> int:
        if self.parent[u] != u:
            self.parent[u] = self.find(self.parent[u])  # Path compression
        return self.parent[u]

    def union(self, u: int, v: int) -> bool:
        root_u = self.find(u)
        root_v = self.find(v)
        if root_u == root_v:
            return False  # Already connected (cycle detected)

        if self.rank[root_u] < self.rank[root_v]:
            self.parent[root_u] = root_v
        elif self.rank[root_u] > self.rank[root_v]:
            self.parent[root_v] = root_u
        else:
            self.parent[root_v] = root_u
            self.rank[root_u] += 1

        self.components -= 1
        return True''',
      ),
    ],
  ),

  // ── A. Arrays and Strings: Additional patterns ─────────────────────────────
  PatternDetail(
    id: 'array_traversal',
    name: 'Array Traversal',
    category: PatternCategories.arraysAndStrings,
    quickIdea: 'Single or multi-directional iteration through contiguous memory in O(n) to process elements.',
    whenToUse: ['Basic element aggregation, filtering, min/max scans, reverse iterations.'],
    recognitionClues: ['Iterate through elements linearly without nested passes.'],
    howItWorks: 'Visits array elements in order using cache-friendly sequential memory reads.',
    variations: ['Left-to-right', 'Right-to-left', 'Two-pointer simultaneous'],
    algorithmSteps: ['Initialize loop index', 'Process element arr[i]', 'Update accumulator'],
    timeComplexity: 'O(n)',
    spaceComplexity: 'O(1)',
    commonMistakes: ['Index out of range', 'Off-by-one at boundaries'],
    edgeCases: ['Empty array', 'Single element'],
    relatedPatterns: ['two_pointers', 'prefix_sum'],
    codeTemplates: [
      CodeTemplate(
        title: 'Array Traversal Scan',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: 'int sumArray(const vector<int>& nums) { int s = 0; for(int x : nums) s += x; return s; }',
        pythonCode: 'def sum_array(nums: list[int]) -> int:\n    return sum(nums)',
      ),
    ],
  ),

  PatternDetail(
    id: 'hashing_frequency',
    name: 'Hashing and Frequency Counting',
    category: PatternCategories.arraysAndStrings,
    quickIdea: 'Use hash maps or frequency arrays to track element counts in O(1) average lookup.',
    whenToUse: ['Two Sum unsorted', 'Anagram checks', 'Finding non-repeating elements', 'Majority element.'],
    recognitionClues: ['"Find duplicates"', '"Element frequency"', '"Unsorted array search"'],
    howItWorks: 'Directly maps keys to counts or indices, trading O(n) memory for O(1) query time.',
    variations: ['Fixed alphabet array (size 26)', 'Hash map for arbitrary numbers'],
    algorithmSteps: ['Create map/array', 'Increment counts for each element', 'Query map for lookup'],
    timeComplexity: 'O(n)',
    spaceComplexity: 'O(n)',
    commonMistakes: ['Ignoring hash collisions', 'Not removing zero-count keys in windowing'],
    edgeCases: ['All identical elements', 'All distinct elements'],
    relatedPatterns: ['prefix_sum', 'fixed_sliding_window'],
    codeTemplates: [
      CodeTemplate(
        title: 'Frequency Counter',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(n)',
        cppCode: '#include <unordered_map>\nusing namespace std;\nunordered_map<int, int> countFreq(const vector<int>& v) { unordered_map<int, int> m; for(int x : v) m[x]++; return m; }',
        pythonCode: 'from collections import Counter\ndef count_freq(v: list[int]): return Counter(v)',
      ),
    ],
  ),

  PatternDetail(
    id: 'difference_array',
    name: 'Difference Array',
    category: PatternCategories.arraysAndStrings,
    quickIdea: 'Apply multiple range update queries [L, R, val] in O(1) each, then compute prefix sum once at the end in O(n).',
    whenToUse: ['Multiple range updates on an array', 'Flight booking seats', 'Corporate flight bookings.'],
    recognitionClues: ['"Add value X to all elements from L to R in multiple queries"'],
    howItWorks: 'diff[L] += val and diff[R+1] -= val. Prefix sum of diff accumulates the changes accurately.',
    variations: ['1D Difference Array', '2D Difference Array (matrix range additions)'],
    algorithmSteps: ['Init diff array of size n + 1', 'For each query [L, R, v]: diff[L] += v; diff[R+1] -= v', 'Prefix sum diff to get final values'],
    timeComplexity: 'O(1) per range update, O(n) prefix reconstruct',
    spaceComplexity: 'O(n)',
    commonMistakes: ['Forgetting diff[R+1] subtraction', 'Index out of bounds on R == n - 1'],
    edgeCases: ['Range covers entire array', 'L == R'],
    relatedPatterns: ['prefix_sum', 'sweep_line_basics'],
    codeTemplates: [
      CodeTemplate(
        title: 'Difference Array Range Update',
        timeComplexity: 'O(n + q)',
        spaceComplexity: 'O(n)',
        cppCode: 'void updateRange(vector<int>& diff, int l, int r, int val) { diff[l] += val; diff[r + 1] -= val; }',
        pythonCode: 'def update_range(diff: list[int], l: int, r: int, val: int): diff[l] += val; diff[r + 1] -= val',
      ),
    ],
  ),

  PatternDetail(
    id: 'kadanes_algorithm',
    name: 'Kadane\'s Algorithm',
    category: PatternCategories.arraysAndStrings,
    quickIdea: 'Find maximum sum contiguous subarray in O(n) time and O(1) space by resetting negative running sums.',
    whenToUse: ['Maximum subarray sum', 'Maximum circular subarray sum.'],
    recognitionClues: ['"Maximum subarray sum"', '"Contiguous elements with largest sum"'],
    howItWorks: 'At each index: currentSum = max(num, currentSum + num). If currentSum becomes negative, discard it.',
    variations: ['Max Subarray Sum', 'Min Subarray Sum', 'Circular Array Max Sum'],
    algorithmSteps: ['currentSum = nums[0], maxSum = nums[0]', 'Loop from index 1: currentSum = max(nums[i], currentSum + nums[i]); maxSum = max(maxSum, currentSum)', 'Return maxSum'],
    timeComplexity: 'O(n)',
    spaceComplexity: 'O(1)',
    commonMistakes: ['Initializing maxSum to 0 when all elements are negative (must be nums[0])'],
    edgeCases: ['All negative numbers in array'],
    relatedPatterns: ['prefix_sum', 'one_dimensional_dp'],
    codeTemplates: [
      CodeTemplate(
        title: 'Kadane\'s Maximum Subarray',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: 'int maxSubArray(const vector<int>& a) { int cur = a[0], mx = a[0]; for(size_t i=1;i<a.size();i++){ cur = max(a[i], cur+a[i]); mx = max(mx, cur); } return mx; }',
        pythonCode: 'def max_sub_array(nums: list[int]) -> int:\n    cur = mx = nums[0]\n    for x in nums[1:]:\n        cur = max(x, cur + x)\n        mx = max(mx, cur)\n    return mx',
      ),
    ],
  ),

  // ── B. Searching and Sorting ────────────────────────────────────────────────
  PatternDetail(
    id: 'binary_search_answer',
    name: 'Binary Search on Answer',
    category: PatternCategories.searchingAndSorting,
    quickIdea: 'Binary search the solution range [minAns, maxAns] whenever a feasibility test is monotonic.',
    whenToUse: ['Capacity to ship packages within D days', 'Koko eating bananas', 'Split array largest sum.'],
    recognitionClues: ['"Minimize the maximum"', '"Maximize the minimum"', 'Direct calculation is hard, but verifying candidate is O(n)'],
    howItWorks: 'Define isPossible(val). If monotonic: F F F T T T, binary search finds the threshold in O(n log(range)).',
    variations: ['Min feasible value', 'Max feasible value'],
    algorithmSteps: ['Identify low and high bounds', 'While low <= high: mid = low + (high-low)/2', 'If isPossible(mid): record mid, test better half', 'Else: test other half'],
    timeComplexity: 'O(n · log(range))',
    spaceComplexity: 'O(1)',
    commonMistakes: ['Incorrect search bounds (low and high)', 'Non-monotonic feasibility function'],
    edgeCases: ['Single item answer', 'Extreme high/low answer'],
    relatedPatterns: ['binary_search', 'lower_upper_bound'],
    codeTemplates: [
      CodeTemplate(
        title: 'Binary Search on Answer',
        timeComplexity: 'O(n log(range))',
        spaceComplexity: 'O(1)',
        cppCode: '// Template: binary search on answer\nint minEatingSpeed(vector<int>& piles, int h) { /* ... */ return 0; }',
        pythonCode: 'def min_eating_speed(piles: list[int], h: int) -> int:\n    # Binary search over [1, max(piles)]\n    pass',
      ),
    ],
  ),

  PatternDetail(
    id: 'merge_intervals',
    name: 'Merge Intervals',
    category: PatternCategories.searchingAndSorting,
    quickIdea: 'Sort intervals by start time, then merge adjacent overlapping intervals in a single O(n) pass.',
    whenToUse: ['Merging overlapping time ranges', 'Insert new interval into calendar.'],
    recognitionClues: ['"Merge overlapping intervals"', '"Given an array of intervals [start, end]"'],
    howItWorks: 'After sorting by start time, overlap occurs iff curr.start <= prev.end. Merge by prev.end = max(prev.end, curr.end).',
    variations: ['Merge Overlapping', 'Insert Interval', 'Employee Free Time'],
    algorithmSteps: ['Sort intervals by start time', 'Iterate through intervals', 'If current overlaps with last merged: extend last.end', 'Else: push current interval'],
    timeComplexity: 'O(n log n)',
    spaceComplexity: 'O(n) for result',
    commonMistakes: ['Forgetting to sort intervals first', 'Not using max(prev.end, curr.end)'],
    edgeCases: ['All intervals overlap into one', 'No intervals overlap'],
    relatedPatterns: ['greedy', 'sweep_line_basics'],
    codeTemplates: [
      CodeTemplate(
        title: 'Merge Intervals',
        timeComplexity: 'O(n log n)',
        spaceComplexity: 'O(n)',
        cppCode: r'''#include <vector>
#include <algorithm>
using namespace std;
vector<vector<int>> merge(vector<vector<int>>& intervals) {
    if (intervals.empty()) return {};
    sort(intervals.begin(), intervals.end());
    vector<vector<int>> merged = {intervals[0]};
    for (size_t i = 1; i < intervals.size(); i++) {
        if (intervals[i][0] <= merged.back()[1]) {
            merged.back()[1] = max(merged.back()[1], intervals[i][1]);
        } else {
            merged.push_back(intervals[i]);
        }
    }
    return merged;
}''',
        pythonCode: r'''def merge(intervals: list[list[int]]) -> list[list[int]]:
    if not intervals: return []
    intervals.sort(key=lambda x: x[0])
    merged = [intervals[0]]
    for start, end in intervals[1:]:
        if start <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    return merged''',
      ),
    ],
  ),

  // ── C. Linked Lists ────────────────────────────────────────────────────────
  PatternDetail(
    id: 'linked_list_reversal',
    name: 'Linked List Reversal',
    category: PatternCategories.linkedLists,
    quickIdea: 'Reverse next pointers in-place using three pointers (prev, curr, next) in O(n) time and O(1) space.',
    whenToUse: ['Reverse entire linked list', 'Reverse nodes in k-group', 'Palindrome linked list verification.'],
    recognitionClues: ['"Reverse linked list"', '"Reverse subsegment [left, right]"'],
    howItWorks: 'Stores curr.next in temp, reverses curr.next = prev, advances prev = curr and curr = temp.',
    variations: ['Iterative 3-pointer', 'Recursive reversal', 'Reverse between [m, n]'],
    algorithmSteps: ['prev = null, curr = head', 'While curr != null: next = curr.next; curr.next = prev; prev = curr; curr = next', 'Return prev as new head'],
    timeComplexity: 'O(n)',
    spaceComplexity: 'O(1)',
    commonMistakes: ['Losing pointer to curr.next before updating link', 'Returning curr instead of prev'],
    edgeCases: ['Empty list', 'Single node list'],
    relatedPatterns: ['dummy_node', 'fast_slow_pointers'],
    codeTemplates: [
      CodeTemplate(
        title: 'Iterative Linked List Reversal',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: 'ListNode* reverseList(ListNode* head) { ListNode* prev = nullptr; ListNode* curr = head; while(curr){ ListNode* nxt = curr->next; curr->next = prev; prev = curr; curr = nxt; } return prev; }',
        pythonCode: 'def reverse_list(head: ListNode | None) -> ListNode | None:\n    prev, curr = None, head\n    while curr:\n        nxt = curr.next\n        curr.next = prev\n        prev = curr\n        curr = nxt\n    return prev',
      ),
    ],
  ),

  PatternDetail(
    id: 'dummy_node',
    name: 'Dummy Node',
    category: PatternCategories.linkedLists,
    quickIdea: 'Prepend a sentinel dummy node before head to eliminate edge cases when modifying the head node.',
    whenToUse: ['Merging two lists', 'Removing elements from list', 'Partitioning list around pivot.'],
    recognitionClues: ['"Remove nth node from end"', '"Merge two sorted lists"', 'Head may be deleted or replaced'],
    howItWorks: 'dummy.next = head ensures that even if head is removed or modified, dummy.next always points to the valid result.',
    variations: ['Dummy head', 'Dummy tail'],
    algorithmSteps: ['dummy = new Node(0, head)', 'Perform node operations using dummy or dummy.next', 'Return dummy.next'],
    timeComplexity: 'O(1) overhead',
    spaceComplexity: 'O(1)',
    commonMistakes: ['Returning dummy instead of dummy.next', 'Memory leak in C++ if dummy is allocated on heap and not freed'],
    edgeCases: ['Head node is deleted', 'All nodes in list are deleted'],
    relatedPatterns: ['linked_list_reversal', 'merge_two_lists'],
    codeTemplates: [
      CodeTemplate(
        title: 'Dummy Node Pattern',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: 'ListNode dummy(0); dummy.next = head; /* manipulate list */ return dummy.next;',
        pythonCode: 'dummy = ListNode(0, head)\n# manipulate list\nreturn dummy.next',
      ),
    ],
  ),

  // ── K. Other Important Patterns: Bit Manipulation ──────────────────────────
  PatternDetail(
    id: 'bit_manipulation',
    name: 'Bit Manipulation & XOR',
    category: PatternCategories.otherImportantPatterns,
    quickIdea: 'Use bitwise operators (AND, OR, XOR, shifts) to check, set, toggle bits or eliminate duplicates in O(1).',
    whenToUse: ['Single Number (all others appear twice)', 'Power of Two check', 'Counting set bits (Hamming weight).'],
    recognitionClues: ['"Find element that appears once"', '"Number of 1 bits"', '"Check if power of two"'],
    howItWorks: 'XOR properties: x ^ x = 0, x ^ 0 = x. Bit trick n & (n - 1) removes lowest set bit.',
    variations: ['XOR Cancellation', 'Bitmask subsets', 'Lowbit isolation (n & -n)'],
    algorithmSteps: ['Use xorSum ^= num for cancellation', 'Use n & (n - 1) to clear lowest set bit'],
    timeComplexity: 'O(1) per bit operation',
    spaceComplexity: 'O(1)',
    commonMistakes: ['Operator precedence: bitwise operators have lower precedence than == in C++/Python! Always parenthesize.'],
    edgeCases: ['Negative integers / sign bit handling', 'Zero'],
    relatedPatterns: ['xor_patterns', 'bitmask_dp'],
    codeTemplates: [
      CodeTemplate(
        title: 'Single Number (XOR Cancellation)',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(1)',
        cppCode: 'int singleNumber(const vector<int>& nums) { int ans = 0; for(int x : nums) ans ^= x; return ans; }',
        pythonCode: 'def single_number(nums: list[int]) -> int:\n    ans = 0\n    for x in nums: ans ^= x\n    return ans',
      ),
    ],
  ),

  // ── K. Other Important Patterns: Trie ──────────────────────────────────────
  PatternDetail(
    id: 'tries',
    name: 'Tries (Prefix Trees)',
    category: PatternCategories.otherImportantPatterns,
    quickIdea: 'Tree data structure where each node represents a character to search and insert prefixes in O(wordLength).',
    whenToUse: ['Autocomplete', 'Spell checkers', 'Prefix matching', 'Word Search II (Trie + Backtracking).'],
    recognitionClues: ['"Words with given prefix"', '"Dictionary lookup"', '"Implement Trie"'],
    howItWorks: 'Nodes share common prefixes, enabling fast O(L) insertion and prefix verification without scanning all dictionary words.',
    variations: ['Standard Trie', 'Bitwise / XOR Trie (max XOR pair)'],
    algorithmSteps: ['Each node has children map and isEnd boolean', 'insert(word): traverse/create nodes, mark end', 'startsWith(prefix): traverse nodes, return true if prefix path exists'],
    timeComplexity: 'O(L) per word of length L',
    spaceComplexity: 'O(total characters in words · alphabet)',
    commonMistakes: ['Not marking isEndOfWord on last node', 'Memory overhead if alphabet is large'],
    edgeCases: ['Empty string', 'Inserting same word multiple times'],
    relatedPatterns: ['string_matching', 'backtracking'],
    codeTemplates: [
      CodeTemplate(
        title: 'Trie Implementation',
        timeComplexity: 'O(L)',
        spaceComplexity: 'O(N · L)',
        cppCode: r'''#include <string>
#include <vector>
using namespace std;

class Trie {
    struct Node {
        Node* next[26] = {nullptr};
        bool isEnd = false;
    };
    Node* root = new Node();
public:
    void insert(const string& word) {
        Node* curr = root;
        for (char c : word) {
            int idx = c - 'a';
            if (!curr->next[idx]) curr->next[idx] = new Node();
            curr = curr->next[idx];
        }
        curr->isEnd = true;
    }
    bool startsWith(const string& prefix) {
        Node* curr = root;
        for (char c : prefix) {
            int idx = c - 'a';
            if (!curr->next[idx]) return false;
            curr = curr->next[idx];
        }
        return true;
    }
};''',
        pythonCode: r'''class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end = False

class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word: str) -> None:
        curr = self.root
        for char in word:
            if char not in curr.children:
                curr.children[char] = TrieNode()
            curr = curr.children[char]
        curr.is_end = True

    def starts_with(self, prefix: str) -> bool:
        curr = self.root
        for char in prefix:
            if char not in curr.children:
                return False
            curr = curr.children[char]
        return True''',
      ),
    ],
  ),
];

// Helper to get all initial pattern summaries
List<PatternSummary> getInitialPatternSummaries() {
  return kPatternDetails.map((d) => PatternSummary(
    id: d.id,
    name: d.name,
    category: d.category,
    quickIdea: d.quickIdea,
    status: d.status,
    checklistPercentage: d.checklistPercentage,
    completedChecklistCount: d.checklistCompletedIds.length,
    isBookmarked: d.isBookmarked,
    lastReviewedAt: d.lastReviewedAt,
  )).toList();
}
