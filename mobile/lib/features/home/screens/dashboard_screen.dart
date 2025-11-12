import React, { useState } from 'react';
import { Search, LogOut, X, Building2, GraduationCap, BookOpen, Lock } from 'lucide-react';

const colleges = [
  'ABC Engineering College',
  'XYZ Institute of Tech',
  'PQR University',
  'National Tech University',
  'Regional Engineering College',
];

const branchesByCollege = {
  'ABC Engineering College': ['Computer Science', 'Electronics & Comm.'],
  'XYZ Institute of Tech': ['Civil Engineering', 'Mechanical Engineering'],
  'PQR University': ['Applied Physics', 'Information Technology'],
  'National Tech University': ['Computer Science', 'Chemical Engineering'],
  'Regional Engineering College': ['Electronics & Comm.', 'Civil Engineering'],
};

const subjectsByCollege = {
  'ABC Engineering College': ['Data Structures', 'Operating Systems', 'Calculus I'],
  'XYZ Institute of Tech': ['Structural Analysis', 'Thermodynamics', 'Fluid Mechanics'],
  'PQR University': ['Quantum Mechanics', 'Linear Algebra', 'Networking Basics'],
  'National Tech University': ['Data Structures', 'Heat Transfer'],
  'Regional Engineering College': ['Digital Logic', 'Concrete Technology'],
};

const collegeAdminEmails = {
  'ABC Engineering College': 'abc_admin@pyqachu.com',
  'XYZ Institute of Tech': 'xyz_admin@pyqachu.com',
  'PQR University': 'pqr_admin@pyqachu.com',
};

export default function DashboardScreen() {
  const [selectedCollege, setSelectedCollege] = useState(null);
  const [selectedBranch, setSelectedBranch] = useState(null);
  const [selectedSubject, setSelectedSubject] = useState(null);
  const [modalType, setModalType] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');

  const openModal = (type) => {
    if (type === 'branch' && !selectedCollege) {
      alert('Please select a college first');
      return;
    }
    if (type === 'subject' && (!selectedCollege || !selectedBranch)) {
      alert('Please select college and branch first');
      return;
    }
    setSearchQuery('');
    setModalType(type);
  };

  const closeModal = () => {
    setModalType(null);
    setSearchQuery('');
  };

  const selectItem = (item) => {
    if (modalType === 'college') {
      setSelectedCollege(item);
      setSelectedBranch(null);
      setSelectedSubject(null);
    } else if (modalType === 'branch') {
      setSelectedBranch(item);
      setSelectedSubject(null);
    } else if (modalType === 'subject') {
      setSelectedSubject(item);
    }
    closeModal();
  };

  const getOptions = () => {
    if (modalType === 'college') return colleges;
    if (modalType === 'branch') return branchesByCollege[selectedCollege] || [];
    if (modalType === 'subject') return subjectsByCollege[selectedCollege] || [];
    return [];
  };

  const options = getOptions();
  const filteredOptions = options.filter(opt =>
    opt.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const isReady = selectedCollege && selectedBranch && selectedSubject;
  const hasAnySelection = selectedCollege || selectedBranch || selectedSubject;

  const clearAll = () => {
    setSelectedCollege(null);
    setSelectedBranch(null);
    setSelectedSubject(null);
  };

  const getIcon = (type) => {
    if (type === 'college') return <Building2 size={24} className="text-gray-600" />;
    if (type === 'branch') return <GraduationCap size={24} className="text-gray-600" />;
    return <BookOpen size={24} className="text-gray-600" />;
  };

  const SearchCard = ({ title, value, placeholder, onClick, enabled }) => (
    <button
      onClick={enabled ? onClick : null}
      disabled={!enabled}
      className="w-full mx-5 my-1.5 p-5 bg-white rounded-2xl shadow-sm hover:shadow-md transition-shadow text-left"
    >
      <div className="flex items-center justify-between">
        <div>
          <div className="text-lg font-semibold text-black mb-1">{title}</div>
          <div className={`text-sm ${value ? 'text-gray-900' : 'text-gray-500'}`}>
            {value || placeholder}
          </div>
        </div>
        {!enabled && <Lock size={20} className="text-gray-400" />}
      </div>
    </button>
  );

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* AppBar */}
      <div className="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold text-lg">
            P
          </div>
          <h1 className="text-lg font-semibold text-black">Find your PYQs</h1>
        </div>
        <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
          <LogOut size={20} className="text-black" />
        </button>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto py-5">
        <SearchCard
          title="Where?"
          value={selectedCollege}
          placeholder="Select college"
          onClick={() => openModal('college')}
          enabled={true}
        />
        <SearchCard
          title="Branch"
          value={selectedBranch}
          placeholder="Add branch"
          onClick={() => openModal('branch')}
          enabled={!!selectedCollege}
        />
        <SearchCard
          title="Subject"
          value={selectedSubject}
          placeholder="Add subject"
          onClick={() => openModal('subject')}
          enabled={!!selectedCollege && !!selectedBranch}
        />
      </div>

      {/* Bottom Action Bar */}
      <div className="bg-white border-t border-gray-200 px-5 py-4 flex items-center justify-between shadow-lg">
        <button
          onClick={clearAll}
          disabled={!hasAnySelection}
          className={`text-base font-semibold underline ${
            hasAnySelection ? 'text-black' : 'text-gray-400'
          }`}
        >
          Clear all
        </button>
        <button
          onClick={() => {
            if (isReady) {
              alert(`Search: ${selectedCollege}, ${selectedBranch}, ${selectedSubject}`);
            }
          }}
          disabled={!isReady}
          className={`flex items-center gap-2 px-6 py-3 rounded-lg font-semibold transition-all ${
            isReady
              ? 'bg-pink-600 hover:bg-pink-700 text-white'
              : 'bg-gray-300 text-gray-600 cursor-not-allowed'
          }`}
        >
          <Search size={20} />
          <span>Search</span>
        </button>
      </div>

      {/* Modal */}
      {modalType && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-end justify-center z-50">
          <div className="bg-white rounded-t-3xl w-full max-w-2xl h-[85vh] flex flex-col animate-slideUp">
            {/* Modal Header */}
            <div className="p-5 border-b border-gray-200">
              <div className="flex items-center justify-between mb-5">
                <h2 className="text-2xl font-semibold">
                  {modalType === 'college' ? 'Where?' : modalType === 'branch' ? 'Branch?' : 'Subject?'}
                </h2>
                <button
                  onClick={closeModal}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                >
                  <X size={24} />
                </button>
              </div>
              
              {/* Search Input */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
                <input
                  type="text"
                  placeholder={modalType === 'college' ? 'Search colleges' : `Search ${modalType}s`}
                  className="w-full pl-10 pr-4 py-3 bg-white border-2 border-gray-300 rounded-xl focus:outline-none focus:border-black transition-colors"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  autoFocus
                />
              </div>

              {modalType === 'college' && (
                <div className="mt-4 text-sm font-semibold text-gray-700">
                  Suggested colleges
                </div>
              )}
            </div>

            {/* Options List */}
            <div className="flex-1 overflow-y-auto">
              {filteredOptions.length > 0 ? (
                <div>
                  {filteredOptions.map((item, idx) => (
                    <button
                      key={idx}
                      onClick={() => selectItem(item)}
                      className="w-full px-5 py-4 hover:bg-gray-50 transition-colors border-b border-gray-100 flex items-center gap-4"
                    >
                      <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        {getIcon(modalType)}
                      </div>
                      <div className="text-left flex-1">
                        <div className="text-base font-medium text-gray-900">{item}</div>
                        <div className="text-sm text-gray-600">
                          {modalType === 'college' ? 'Engineering College' : modalType === 'branch' ? 'Department' : 'Course'}
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              ) : (
                <div className="p-6 text-center text-gray-500 text-sm">
                  {modalType === 'college'
                    ? 'College not found? Mail to moderator@pyqachu.com'
                    : `No ${modalType} found. Mail to ${collegeAdminEmails[selectedCollege] || 'admin@pyqachu.com'}`}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      <style>{`
        @keyframes slideUp {
          from {
            transform: translateY(100%);
          }
          to {
            transform: translateY(0);
          }
        }
        .animate-slideUp {
          animation: slideUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
      `}</style>
    </div>
  );
}