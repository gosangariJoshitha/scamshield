"""Append traceable multilingual scam-pattern illustrations to the corpus and KB."""

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATASET_PATH = ROOT / "ml" / "data" / "raw" / "scamshield_dataset_2000_cleaned.csv"
KNOWLEDGE_PATH = ROOT / "backend" / "data" / "knowledgebase_100_articles.json"

SOURCES = {
    "RBI": {
        "name": "RBI digital-payment safety guidance",
        "url": "https://rbikehtahai.rbi.org.in/qr",
    },
    "I4C": {
        "name": "I4C / National Cyber Crime Reporting Portal advisories",
        "url": "https://www.cybercrime.gov.in/Webform/Advisory.aspx",
    },
    "FTC": {
        "name": "FTC Consumer Advice: Online Scams",
        "url": "https://consumer.ftc.gov/online-scams",
    },
    "CISA": {
        "name": "CISA: Avoiding Social Engineering and Phishing Attacks",
        "url": "https://www.cisa.gov/news-events/news/avoiding-social-engineering-and-phishing-attacks",
    },
}

SAFE_ACTION = {
    "en": "Do not pay, share a one-time code, install remote-access software, or follow an unsolicited link or QR code. Verify independently through the provider's official app or a number you already trust.",
    "hi": "पैसे न भेजें, OTP साझा न करें, रिमोट-एक्सेस ऐप इंस्टॉल न करें और अनचाहे लिंक या QR कोड का उपयोग न करें। संस्था के आधिकारिक ऐप या पहले से ज्ञात नंबर से स्वतंत्र रूप से पुष्टि करें।",
    "te": "డబ్బు పంపవద్దు, OTP పంచుకోవద్దు, రిమోట్ యాక్సెస్ యాప్ ఇన్‌స్టాల్ చేయవద్దు; అనుకోని లింక్ లేదా QR కోడ్‌ను ఉపయోగించవద్దు. సంస్థ అధికారిక యాప్ లేదా ముందుగా తెలిసిన నంబర్ ద్వారా స్వతంత్రంగా నిర్ధారించండి.",
}

RESOLUTION_STEPS = {
    "en": [
        "1. Stop the conversation and do not follow the supplied payment, link, code, or software instructions.",
        "2. Verify the claim independently using the provider's official app, website, or a previously trusted contact method.",
        "3. If money or account access was exposed, contact your bank or provider promptly, preserve the message and transaction details, and report suspected fraud to the appropriate cybercrime authority.",
    ],
    "hi": [
        "1. बातचीत रोकें और दिए गए भुगतान, लिंक, कोड या सॉफ़्टवेयर निर्देशों का पालन न करें।",
        "2. संस्था के आधिकारिक ऐप, वेबसाइट या पहले से विश्वसनीय संपर्क माध्यम से दावे की स्वतंत्र पुष्टि करें।",
        "3. यदि पैसे या खाते की पहुँच साझा हुई है, तो तुरंत बैंक/सेवा प्रदाता से संपर्क करें, संदेश और लेन-देन का विवरण सुरक्षित रखें तथा संबंधित साइबर अपराध प्राधिकरण को रिपोर्ट करें।",
    ],
    "te": [
        "1. సంభాషణను ఆపి, ఇచ్చిన చెల్లింపు, లింక్, కోడ్ లేదా సాఫ్ట్‌వేర్ సూచనలను అనుసరించవద్దు.",
        "2. సంస్థ అధికారిక యాప్, వెబ్‌సైట్ లేదా ముందుగా విశ్వసించిన సంప్రదింపు మార్గం ద్వారా దావాను స్వతంత్రంగా నిర్ధారించండి.",
        "3. డబ్బు లేదా ఖాతా యాక్సెస్ బయటపడితే, వెంటనే బ్యాంక్/సేవా ప్రదాతను సంప్రదించండి; సందేశం, లావాదేవీ వివరాలు భద్రపరచి సంబంధిత సైబర్‌క్రైమ్ అధికారులకు నివేదించండి.",
    ],
}

VARIANTS = {
    "en": [
        {"amount": "₹450", "reference": "A17", "time": "today"},
        {"amount": "₹1,250", "reference": "B26", "time": "before 6 PM"},
        {"amount": "₹2,800", "reference": "C35", "time": "within 20 minutes"},
        {"amount": "₹999", "reference": "D44", "time": "before the request expires"},
    ],
    "hi": [
        {"amount": "₹450", "reference": "A17", "time": "आज"},
        {"amount": "₹1,250", "reference": "B26", "time": "शाम 6 बजे से पहले"},
        {"amount": "₹2,800", "reference": "C35", "time": "20 मिनट के भीतर"},
        {"amount": "₹999", "reference": "D44", "time": "अनुरोध समाप्त होने से पहले"},
    ],
    "te": [
        {"amount": "₹450", "reference": "A17", "time": "ఈరోజు"},
        {"amount": "₹1,250", "reference": "B26", "time": "సాయంత్రం 6 గంటలలోపు"},
        {"amount": "₹2,800", "reference": "C35", "time": "20 నిమిషాల్లో"},
        {"amount": "₹999", "reference": "D44", "time": "అభ్యర్థన గడువు ముగిసేలోపు"},
    ],
}

PATTERNS = [
    {
        "pattern": "accidental_transfer",
        "title": "Accidental Transfer Refund Scam",
        "overview": "A stranger claims to have transferred money by mistake and asks the recipient to scan a QR code, approve a collect request, or enter a payment PIN to return it. A received-money claim must be checked in the payment app; a PIN or approval can authorize an outgoing payment.",
        "source": "RBI",
        "severity": "HIGH",
        "signals": {
            "en": "A stranger asks the recipient to scan a QR code or enter a payment PIN to receive or return money.",
            "hi": "अजनबी पैसे पाने या लौटाने के लिए QR कोड स्कैन करने अथवा भुगतान PIN डालने को कहता है।",
            "te": "డబ్బు అందుకోవడానికి లేదా తిరిగి పంపడానికి QR కోడ్ స్కాన్ చేయమని లేదా చెల్లింపు PIN నమోదు చేయమని అపరిచితుడు అడుగుతాడు.",
        },
        "messages": {
            "en": {
                "scam": "I transferred {amount} to your UPI by mistake. Scan this QR and enter your PIN to return it {time}.",
                "genuine": "Your {amount} transfer is complete. Check the receipt in your payment app; no QR scan or PIN is needed to receive a refund.",
            },
            "hi": {
                "scam": "गलती से आपके UPI पर {amount} भेज दिए। वापस करने के लिए यह QR स्कैन करके अपना PIN डालें {time}।",
                "genuine": "आपका {amount} का भुगतान पूरा हो गया है। रसीद भुगतान ऐप में देखें; रिफंड पाने के लिए QR स्कैन या PIN की जरूरत नहीं है।",
            },
            "te": {
                "scam": "పొరపాటున మీ UPIకి {amount} పంపాను. తిరిగి పంపడానికి ఈ QR స్కాన్ చేసి మీ PIN నమోదు చేయండి {time}.",
                "genuine": "మీ {amount} బదిలీ పూర్తయింది. రసీదును చెల్లింపు యాప్‌లో చూడండి; రిఫండ్ పొందడానికి QR స్కాన్ లేదా PIN అవసరం లేదు.",
            },
        },
    },
    {
        "pattern": "electricity_disconnection",
        "title": "Electricity Disconnection Impersonation",
        "overview": "An unsolicited message or caller threatens immediate power disconnection and directs the recipient to an unofficial number, link, or personal payment account. Verify a bill or outage notice in the utility's official channels.",
        "source": "I4C",
        "severity": "HIGH",
        "signals": {
            "en": "An immediate disconnection threat is paired with an unofficial callback number or payment route.",
            "hi": "तुरंत बिजली काटने की धमकी के साथ अनधिकृत नंबर या भुगतान माध्यम दिया जाता है।",
            "te": "వెంటనే విద్యుత్ నిలిపివేస్తామని బెదిరించి అనధికార నంబర్ లేదా చెల్లింపు మార్గం ఇస్తారు.",
        },
        "messages": {
            "en": {
                "scam": "Your electricity will be disconnected {time}. Pay {amount} to this personal account and call the agent at the number in this message.",
                "genuine": "A planned maintenance window may interrupt electricity {time}. Check the schedule in the utility's official app; no payment or callback is requested.",
            },
            "hi": {
                "scam": "{time} बिजली काट दी जाएगी। {amount} इस निजी खाते में भेजें और संदेश में दिए एजेंट के नंबर पर कॉल करें।",
                "genuine": "{time} नियोजित रखरखाव से बिजली बाधित हो सकती है। आधिकारिक ऐप में समय देखें; भुगतान या वापस कॉल करने की मांग नहीं है।",
            },
            "te": {
                "scam": "మీ విద్యుత్ {time} నిలిపివేస్తారు. {amount} ఈ వ్యక్తిగత ఖాతాకు చెల్లించి, సందేశంలోని ఏజెంట్ నంబర్‌కు కాల్ చేయండి.",
                "genuine": "{time} ప్రణాళికాబద్ధమైన నిర్వహణ వల్ల విద్యుత్ అంతరాయం ఉండవచ్చు. అధికారిక యాప్‌లో షెడ్యూల్ చూడండి; చెల్లింపు లేదా కాల్ చేయమని అడగలేదు.",
            },
        },
    },
    {
        "pattern": "lottery_scam",
        "title": "Lottery Prize and Advance-Fee Scam",
        "overview": "A message announces an unexpected prize but demands an advance processing, tax, or release payment or sensitive account information before the prize can be received. Independently verify the contest and never pay a stranger to unlock an unverified prize.",
        "source": "FTC",
        "severity": "HIGH",
        "signals": {
            "en": "An unexpected prize is conditional on an advance payment, one-time code, or bank details.",
            "hi": "अप्रत्याशित इनाम पाने के लिए पहले शुल्क, OTP या बैंक विवरण मांगे जाते हैं।",
            "te": "అనుకోని బహుమతిని పొందడానికి ముందస్తు ఫీజు, OTP లేదా బ్యాంక్ వివరాలు అడుగుతారు.",
        },
        "messages": {
            "en": {
                "scam": "You won a {amount} prize! Pay a release fee {time} and send the receipt plus your bank OTP to claim it.",
                "genuine": "The contest results are published on the organizer's official website. Review the eligibility rules there; no advance fee or bank OTP is required to view results.",
            },
            "hi": {
                "scam": "आपने {amount} का इनाम जीता है! दावा करने के लिए {time} रिलीज़ शुल्क दें और रसीद के साथ बैंक OTP भेजें।",
                "genuine": "प्रतियोगिता के परिणाम आयोजक की आधिकारिक वेबसाइट पर हैं। पात्रता नियम वहीं देखें; परिणाम देखने के लिए अग्रिम शुल्क या बैंक OTP नहीं चाहिए।",
            },
            "te": {
                "scam": "మీరు {amount} బహుమతి గెలిచారు! పొందడానికి {time} విడుదల ఫీజు చెల్లించి రసీదు, బ్యాంక్ OTP పంపండి.",
                "genuine": "పోటీ ఫలితాలు నిర్వాహకుడి అధికారిక వెబ్‌సైట్‌లో ఉన్నాయి. అర్హత నియమాలు అక్కడ చూడండి; ఫలితాలు చూడటానికి ముందస్తు ఫీజు లేదా బ్యాంక్ OTP అవసరం లేదు.",
            },
        },
    },
    {
        "pattern": "customs_fee_scam",
        "title": "Fake Customs or Parcel Release Fee",
        "overview": "A parcel notice claims that a small customs, address-correction, or release fee is due and uses a link or urgent deadline to collect payment or card details. Check shipment status directly in the courier's official app or website.",
        "source": "FTC",
        "severity": "HIGH",
        "signals": {
            "en": "A parcel is held until a small urgent fee is paid through an unsolicited link.",
            "hi": "पार्सल रोकने का दावा कर अनचाहे लिंक से तुरंत छोटा शुल्क मांगा जाता है।",
            "te": "పార్సెల్ నిలిపివేశామని చెప్పి అనుకోని లింక్ ద్వారా వెంటనే చిన్న ఫీజు అడుగుతారు.",
        },
        "messages": {
            "en": {
                "scam": "Your parcel is held for customs. Pay {amount} through this link {time} or it will be returned; enter your card details.",
                "genuine": "Shipment {reference} has a tracking update. Check its status in the courier's official app; do not use a payment link in an unexpected message.",
            },
            "hi": {
                "scam": "सीमा शुल्क के कारण आपका पार्सल रुका है। {time} इस लिंक से {amount} दें, नहीं तो पार्सल लौट जाएगा; कार्ड विवरण भरें।",
                "genuine": "शिपमेंट {reference} की ट्रैकिंग अपडेट हुई है। कूरियर के आधिकारिक ऐप में स्थिति देखें; अनपेक्षित संदेश के भुगतान लिंक का उपयोग न करें।",
            },
            "te": {
                "scam": "కస్టమ్స్ కారణంగా మీ పార్సెల్ నిలిపివేశారు. {time} ఈ లింక్ ద్వారా {amount} చెల్లించండి, లేకపోతే తిరిగి పంపిస్తారు; కార్డు వివరాలు నమోదు చేయండి.",
                "genuine": "షిప్‌మెంట్ {reference}కు ట్రాకింగ్ అప్‌డేట్ ఉంది. కూరియర్ అధికారిక యాప్‌లో స్థితి చూడండి; అనుకోని సందేశంలోని చెల్లింపు లింక్‌ను ఉపయోగించవద్దు.",
            },
        },
    },
    {
        "pattern": "sim_swap",
        "title": "SIM Swap and Number-Takeover Scam",
        "overview": "A caller or message impersonates a mobile provider and requests an OTP, account PIN, or identity details under the pretext of preventing disconnection or activating a replacement SIM. Contact the carrier using its official app or published support channel.",
        "source": "RBI",
        "severity": "HIGH",
        "signals": {
            "en": "An unsolicited caller requests an OTP or account PIN to activate, replace, or protect a SIM.",
            "hi": "अनचाही कॉल में SIM चालू, बदलने या सुरक्षित करने के लिए OTP या अकाउंट PIN मांगा जाता है।",
            "te": "SIM యాక్టివేషన్, మార్పు లేదా రక్షణ పేరుతో అనుకోని కాల్‌లో OTP లేదా ఖాతా PIN అడుగుతారు.",
        },
        "messages": {
            "en": {
                "scam": "Your number will be blocked {time}. Read me the OTP sent to your phone so I can activate the replacement SIM.",
                "genuine": "A SIM replacement request was recorded for your account. If you did not request it, contact the carrier through its official app; never share an OTP with a caller.",
            },
            "hi": {
                "scam": "{time} आपका नंबर बंद होगा। नया SIM चालू करने के लिए फोन पर आया OTP मुझे बताएं।",
                "genuine": "आपके खाते में SIM बदलने का अनुरोध दर्ज है। यदि आपने अनुरोध नहीं किया, तो आधिकारिक ऐप से कंपनी से संपर्क करें; कॉलर को OTP न बताएं।",
            },
            "te": {
                "scam": "{time} మీ నంబర్ నిలిపివేస్తారు. కొత్త SIM యాక్టివేట్ చేయడానికి ఫోన్‌కు వచ్చిన OTP చెప్పండి.",
                "genuine": "మీ ఖాతాకు SIM మార్పు అభ్యర్థన నమోదైంది. మీరు అడగకపోతే అధికారిక యాప్ ద్వారా క్యారియర్‌ను సంప్రదించండి; కాలర్‌కు OTP చెప్పవద్దు.",
            },
        },
    },
    {
        "pattern": "remote_access_scam",
        "title": "Remote-Access Support Scam",
        "overview": "A supposed support agent pressures someone to install remote-control software or share a screen, then attempts to access accounts or authorize payments. Unsolicited callers should not receive remote access to financial devices.",
        "source": "CISA",
        "severity": "HIGH",
        "signals": {
            "en": "An unsolicited agent asks to install remote-control software or reveal a screen to resolve a security or payment issue.",
            "hi": "अनचाहा एजेंट सुरक्षा या भुगतान समस्या के बहाने रिमोट-कंट्रोल ऐप इंस्टॉल या स्क्रीन साझा करने को कहता है।",
            "te": "అనుకోని ఏజెంట్ భద్రత లేదా చెల్లింపు సమస్య పేరుతో రిమోట్ కంట్రోల్ యాప్ ఇన్‌స్టాల్ చేయమని లేదా స్క్రీన్ పంచుకోమని అడుగుతాడు.",
        },
        "messages": {
            "en": {
                "scam": "I am support. Install this remote-control app {time} so I can reverse the {amount} charge; keep your banking app open.",
                "genuine": "For your support case, use the provider's official help app or published support channel. Do not install remote-access tools at an unsolicited caller's request.",
            },
            "hi": {
                "scam": "मैं सहायता विभाग से हूं। {amount} का भुगतान लौटाने के लिए {time} यह रिमोट ऐप इंस्टॉल करें और बैंक ऐप खुला रखें।",
                "genuine": "सहायता के लिए कंपनी का आधिकारिक ऐप या प्रकाशित सहायता माध्यम इस्तेमाल करें। अनचाही कॉल पर रिमोट-एक्सेस ऐप इंस्टॉल न करें।",
            },
            "te": {
                "scam": "నేను సపోర్ట్ నుంచి మాట్లాడుతున్నాను. {amount} ఛార్జీని వెనక్కి ఇవ్వడానికి {time} ఈ రిమోట్ యాప్ ఇన్‌స్టాల్ చేసి బ్యాంక్ యాప్ తెరిచి ఉంచండి.",
                "genuine": "సహాయం కోసం సంస్థ అధికారిక యాప్ లేదా ప్రచురించిన సపోర్ట్ మార్గాన్ని ఉపయోగించండి. అనుకోని కాలర్ చెప్పాడని రిమోట్ యాక్సెస్ యాప్ ఇన్‌స్టాల్ చేయవద్దు.",
            },
        },
    },
    {
        "pattern": "romance_scam",
        "title": "Romance and Emergency-Money Scam",
        "overview": "A person met online builds trust and then describes an emergency, travel problem, or investment opportunity that requires money, gift cards, cryptocurrency, or account access. Verify identity independently and do not send money to someone you have not met and verified.",
        "source": "FTC",
        "severity": "HIGH",
        "signals": {
            "en": "A new online relationship quickly develops an urgent request for money while avoiding in-person or independent verification.",
            "hi": "नई ऑनलाइन पहचान जल्दी ही पैसों की आपात मांग करती है और स्वतंत्र पहचान-पुष्टि से बचती है।",
            "te": "కొత్త ఆన్‌లైన్ పరిచయం త్వరగా డబ్బు అత్యవసరంగా అడిగి స్వతంత్ర గుర్తింపు నిర్ధారణను తప్పించుకుంటుంది.",
        },
        "messages": {
            "en": {
                "scam": "I trust only you. Send {amount} for my emergency {time}; please keep this private and do not call my family.",
                "genuine": "I cannot lend money to someone I have only met online. I will verify your identity independently and will not share financial credentials.",
            },
            "hi": {
                "scam": "मुझे केवल आप पर भरोसा है। मेरी आपात स्थिति के लिए {time} {amount} भेजें; इसे निजी रखें और मेरे परिवार को कॉल न करें।",
                "genuine": "मैं केवल ऑनलाइन मिले व्यक्ति को पैसे नहीं भेजूंगा/भेजूंगी। आपकी पहचान स्वतंत्र रूप से जांचूंगा/जांचूंगी और वित्तीय जानकारी साझा नहीं करूंगा/करूंगी।",
            },
            "te": {
                "scam": "నాకు మీరే నమ్మకం. నా అత్యవసర పరిస్థితికి {time} {amount} పంపండి; ఇది రహస్యంగా ఉంచి నా కుటుంబానికి కాల్ చేయవద్దు.",
                "genuine": "ఆన్‌లైన్‌లో మాత్రమే పరిచయమైన వ్యక్తికి నేను డబ్బు పంపను. మీ గుర్తింపును స్వతంత్రంగా నిర్ధారిస్తాను; ఆర్థిక వివరాలు పంచుకోను.",
            },
        },
    },
    {
        "pattern": "task_job_scam",
        "title": "Task or Job Deposit Scam",
        "overview": "A recruiter promises easy earnings for liking posts, rating products, or completing simple tasks, then asks the worker to deposit money to unlock tasks or withdraw a displayed balance. Verify an employer and never pay to receive wages.",
        "source": "FTC",
        "severity": "HIGH",
        "signals": {
            "en": "A simple online job displays earnings but requires a personal deposit, recharge, or fee before withdrawal.",
            "hi": "ऑनलाइन आसान काम की कमाई दिखाकर निकासी से पहले निजी जमा, रिचार्ज या शुल्क मांगा जाता है।",
            "te": "ఆన్‌లైన్ సులభ పనికి ఆదాయం చూపించి, తీసుకునే ముందు వ్యక్తిగత డిపాజిట్, రీచార్జ్ లేదా ఫీజు అడుగుతారు.",
        },
        "messages": {
            "en": {
                "scam": "Complete these ratings to earn {amount}. Recharge your task wallet {time} to unlock the next level and withdraw your balance.",
                "genuine": "The employer's public careers page lists the role and application process. Review the written terms; legitimate wages are not unlocked by depositing your own money.",
            },
            "hi": {
                "scam": "इन रेटिंग से {amount} कमाएं। अगला स्तर खोलने और बैलेंस निकालने के लिए {time} टास्क वॉलेट में पैसे डालें।",
                "genuine": "नियोक्ता की सार्वजनिक करियर वेबसाइट पर पद और आवेदन प्रक्रिया दी है। लिखित शर्तें पढ़ें; वेतन पाने के लिए अपनी रकम जमा करना आवश्यक नहीं होता।",
            },
            "te": {
                "scam": "ఈ రేటింగ్‌లు పూర్తి చేసి {amount} సంపాదించండి. తదుపరి స్థాయిని తెరిచి బ్యాలెన్స్ తీసుకోవడానికి {time} టాస్క్ వాలెట్‌కు డబ్బు జమ చేయండి.",
                "genuine": "ఉద్యోగి పబ్లిక్ కెరీర్ పేజీలో ఉద్యోగం, దరఖాస్తు విధానం ఉన్నాయి. రాతపూర్వక నిబంధనలు చూడండి; జీతం పొందడానికి మీ డబ్బు జమ చేయాల్సిన అవసరం లేదు.",
            },
        },
    },
    {
        "pattern": "deepfake_impersonation",
        "title": "Voice or Video Impersonation Scam",
        "overview": "A caller or voice/video message appears to come from a relative, executive, or official and demands an urgent transfer or confidential information. A convincing voice or image is not identity proof; confirm using a separate known channel.",
        "source": "CISA",
        "severity": "HIGH",
        "signals": {
            "en": "A familiar-sounding person demands secrecy and an urgent transfer but discourages a callback to a known number.",
            "hi": "परिचित जैसी आवाज़ गोपनीयता और तुरंत पैसे मांगती है तथा ज्ञात नंबर पर वापस कॉल करने से रोकती है।",
            "te": "పరిచయమైన స్వరంలా వినిపించే వ్యక్తి రహస్యంగా వెంటనే డబ్బు అడిగి, తెలిసిన నంబర్‌కు తిరిగి కాల్ చేయొద్దంటాడు.",
        },
        "messages": {
            "en": {
                "scam": "It's me, don't call back. Transfer {amount} {time} to this new account and keep this voice message private.",
                "genuine": "I received a request that sounds like you asking for {amount}. I will call your saved number to confirm before taking any action.",
            },
            "hi": {
                "scam": "मैं ही हूं, वापस कॉल मत करें। {time} इस नए खाते में {amount} भेजें और इस आवाज़ वाले संदेश को गोपनीय रखें।",
                "genuine": "मुझे आपकी जैसी आवाज़ में {amount} मांगने का संदेश मिला। कोई कदम उठाने से पहले आपके सेव किए नंबर पर कॉल करके पुष्टि करूंगा/करूंगी।",
            },
            "te": {
                "scam": "నేనే, తిరిగి కాల్ చేయవద్దు. {time} ఈ కొత్త ఖాతాకు {amount} పంపి ఈ వాయిస్ సందేశాన్ని రహస్యంగా ఉంచండి.",
                "genuine": "{amount} అడుగుతూ మీలా వినిపించే సందేశం వచ్చింది. ఏ చర్యకైనా ముందు సేవ్ చేసిన మీ నంబర్‌కు కాల్ చేసి నిర్ధారిస్తాను.",
            },
        },
    },
    {
        "pattern": "upi_collect_request",
        "title": "UPI Collect Request or Payment-PIN Scam",
        "overview": "A sender frames a UPI collect request, QR scan, or PIN entry as a way to receive money, a refund, or a reward. In a payment app, entering a PIN or approving a collect request can authorize money leaving the account; review the transaction details before approving.",
        "source": "RBI",
        "severity": "HIGH",
        "signals": {
            "en": "The recipient is told to approve a payment request or enter a PIN to receive money or a refund.",
            "hi": "पैसे या रिफंड पाने के लिए भुगतान अनुरोध मंजूर करने या PIN डालने को कहा जाता है।",
            "te": "డబ్బు లేదా రిఫండ్ అందుకోవడానికి చెల్లింపు అభ్యర్థనను ఆమోదించమని లేదా PIN నమోదు చేయమని చెబుతారు.",
        },
        "messages": {
            "en": {
                "scam": "Approve this UPI collect request for {amount} and enter your PIN to receive your refund {time}.",
                "genuine": "A payment of {amount} was sent to the payee you selected. Check the recipient and amount in your app before approving any separate request.",
            },
            "hi": {
                "scam": "रिफंड पाने के लिए {time} {amount} का यह UPI अनुरोध मंजूर करें और PIN डालें।",
                "genuine": "आपके चुने प्राप्तकर्ता को {amount} का भुगतान भेजा गया। किसी अलग अनुरोध को मंजूर करने से पहले ऐप में नाम और राशि जांचें।",
            },
            "te": {
                "scam": "రిఫండ్ పొందడానికి {time} {amount} UPI కలెక్ట్ అభ్యర్థనను ఆమోదించి PIN నమోదు చేయండి.",
                "genuine": "మీరు ఎంచుకున్న గ్రహీతకు {amount} చెల్లింపు పంపబడింది. వేరే అభ్యర్థనను ఆమోదించే ముందు యాప్‌లో గ్రహీత, మొత్తాన్ని తనిఖీ చేయండి.",
            },
        },
    },
    {
        "pattern": "money_mule_recruitment",
        "title": "Money-Mule Recruitment Scam",
        "overview": "A supposed employer offers commission for receiving money into a personal account and forwarding it elsewhere, sometimes asking for identity documents or banking access. Do not move funds for an unknown party; verify the employer and seek advice from your bank if funds arrive unexpectedly.",
        "source": "I4C",
        "severity": "HIGH",
        "signals": {
            "en": "An unknown recruiter asks to use a personal bank account to receive, withdraw, or forward other people's money.",
            "hi": "अज्ञात भर्ती करने वाला दूसरों का पैसा पाने, निकालने या आगे भेजने के लिए निजी बैंक खाता इस्तेमाल करने को कहता है।",
            "te": "తెలియని రిక్రూటర్ ఇతరుల డబ్బును స్వీకరించడానికి, తీసుకోవడానికి లేదా పంపడానికి వ్యక్తిగత బ్యాంక్ ఖాతాను ఉపయోగించమంటాడు.",
        },
        "messages": {
            "en": {
                "scam": "Earn {amount} commission by receiving client funds and forwarding them to this account {time}. Send your bank login to set up payroll.",
                "genuine": "The employer's written offer describes salary and duties. Do not receive or forward customer funds through your personal account as a condition of employment.",
            },
            "hi": {
                "scam": "ग्राहक का पैसा लेकर इस खाते में भेजें और {time} {amount} कमीशन पाएं। वेतन शुरू करने के लिए बैंक लॉगिन भेजें।",
                "genuine": "नियोक्ता के लिखित प्रस्ताव में वेतन और काम का विवरण है। नौकरी की शर्त के रूप में निजी खाते से ग्राहकों का पैसा न लें या आगे न भेजें।",
            },
            "te": {
                "scam": "కస్టమర్ డబ్బు స్వీకరించి ఈ ఖాతాకు పంపితే {time} {amount} కమీషన్ సంపాదించండి. పేరోల్ కోసం బ్యాంక్ లాగిన్ పంపండి.",
                "genuine": "ఉద్యోగి రాతపూర్వక ఆఫర్‌లో జీతం, బాధ్యతలు వివరించబడ్డాయి. ఉద్యోగ షరతుగా వ్యక్తిగత ఖాతా ద్వారా కస్టమర్ డబ్బు స్వీకరించవద్దు లేదా పంపవద్దు.",
            },
        },
    },
    {
        "pattern": "crypto_recovery_scam",
        "title": "Cryptocurrency Recovery or Reimbursement Scam",
        "overview": "Someone claiming to recover lost cryptocurrency or reverse a transaction requests an upfront fee, wallet seed phrase, private key, or remote access. A recovery promise does not justify sharing wallet credentials; independently verify any service and beware of repeat targeting.",
        "source": "FTC",
        "severity": "HIGH",
        "signals": {
            "en": "A supposed recovery service guarantees a refund but first requests cryptocurrency, a seed phrase, private key, or wallet access.",
            "hi": "कथित रिकवरी सेवा रिफंड की गारंटी देकर पहले क्रिप्टो शुल्क, सीड फ्रेज़, निजी कुंजी या वॉलेट एक्सेस मांगती है।",
            "te": "రికవరీ సేవ రిఫండ్ హామీ ఇస్తూ ముందుగా క్రిప్టో ఫీజు, సీడ్ ఫ్రేజ్, ప్రైవేట్ కీ లేదా వాలెట్ యాక్సెస్ అడుగుతుంది.",
        },
        "messages": {
            "en": {
                "scam": "We can recover your {amount} crypto loss {time}. Pay our fee first and send your wallet seed phrase to verify ownership.",
                "genuine": "Keep your wallet recovery phrase private. Contact the wallet provider through its official support site and do not pay an unsolicited recovery agent.",
            },
            "hi": {
                "scam": "{time} आपका {amount} क्रिप्टो नुकसान वापस दिला देंगे। पहले शुल्क दें और स्वामित्व जांचने के लिए वॉलेट सीड फ्रेज़ भेजें।",
                "genuine": "वॉलेट की रिकवरी फ्रेज़ निजी रखें। आधिकारिक सहायता वेबसाइट से वॉलेट प्रदाता से संपर्क करें और अनचाहे रिकवरी एजेंट को पैसे न दें।",
            },
            "te": {
                "scam": "{time} మీ {amount} క్రిప్టో నష్టాన్ని తిరిగి తెస్తాం. ముందుగా ఫీజు చెల్లించి యాజమాన్య నిర్ధారణకు వాలెట్ సీడ్ ఫ్రేజ్ పంపండి.",
                "genuine": "వాలెట్ రికవరీ ఫ్రేజ్‌ను రహస్యంగా ఉంచండి. అధికారిక సపోర్ట్ సైట్ ద్వారా వాలెట్ ప్రొవైడర్‌ను సంప్రదించండి; అనుకోని రికవరీ ఏజెంట్‌కు చెల్లించవద్దు.",
            },
        },
    },
    {
        "pattern": "social_media_account_recovery",
        "title": "Social-Media Account Recovery Impersonation",
        "overview": "An unsolicited account-security message claims that a social-media profile will be removed or has been compromised and directs the recipient to a login link or requests a verification code. Open the platform directly and review security alerts in its official app.",
        "source": "CISA",
        "severity": "HIGH",
        "signals": {
            "en": "A message threatens account deletion and asks for a password, one-time code, or login through a supplied link.",
            "hi": "खाता हटाने की धमकी देकर लिंक से लॉगिन, पासवर्ड या OTP मांगा जाता है।",
            "te": "ఖాతా తొలగిస్తామని బెదిరించి ఇచ్చిన లింక్‌లో లాగిన్, పాస్‌వర్డ్ లేదా OTP అడుగుతారు.",
        },
        "messages": {
            "en": {
                "scam": "Your profile will be disabled {time}. Sign in at this link and send the verification code to confirm your identity.",
                "genuine": "A security alert is available in your social platform's official app. Open the app directly to review it; never send a login code to another person.",
            },
            "hi": {
                "scam": "{time} आपकी प्रोफ़ाइल बंद होगी। इस लिंक पर लॉगिन करें और पहचान की पुष्टि के लिए verification code भेजें।",
                "genuine": "सोशल प्लेटफ़ॉर्म के आधिकारिक ऐप में सुरक्षा सूचना उपलब्ध है। सूचना देखने के लिए ऐप सीधे खोलें; लॉगिन कोड किसी को न भेजें।",
            },
            "te": {
                "scam": "{time} మీ ప్రొఫైల్ నిలిపివేస్తారు. ఈ లింక్‌లో సైన్ ఇన్ చేసి గుర్తింపు నిర్ధారణ కోడ్ పంపండి.",
                "genuine": "సోషల్ ప్లాట్‌ఫారమ్ అధికారిక యాప్‌లో భద్రతా అలర్ట్ ఉంది. దాన్ని చూడటానికి యాప్‌ను నేరుగా తెరవండి; లాగిన్ కోడ్‌ను మరొకరికి పంపవద్దు.",
            },
        },
    },
    {
        "pattern": "tech_support_scam",
        "title": "Fake Technical-Support Warning",
        "overview": "A pop-up, call, or message invents a device infection or account emergency and pressures the recipient to call an unverified support number, install software, or pay for a fix. Close the alert and contact the device or service provider through a known official route.",
        "source": "FTC",
        "severity": "HIGH",
        "signals": {
            "en": "A frightening device warning tells the recipient to call an unsolicited number, install remote software, or pay immediately.",
            "hi": "डिवाइस की डरावनी चेतावनी अनचाहे नंबर पर कॉल, रिमोट ऐप या तुरंत भुगतान के लिए दबाव डालती है।",
            "te": "భయపెట్టే పరికర హెచ్చరిక అనుకోని నంబర్‌కు కాల్, రిమోట్ యాప్ లేదా వెంటనే చెల్లించమని ఒత్తిడి చేస్తుంది.",
        },
        "messages": {
            "en": {
                "scam": "Critical virus detected! Call the support number on this screen and pay {amount} {time}; do not close this warning.",
                "genuine": "For device help, open the manufacturer's official support site yourself. Do not rely on a pop-up number or grant remote access to an unsolicited caller.",
            },
            "hi": {
                "scam": "गंभीर वायरस मिला! स्क्रीन पर दिए सहायता नंबर पर कॉल करें और {time} {amount} दें; चेतावनी बंद न करें।",
                "genuine": "डिवाइस सहायता के लिए निर्माता की आधिकारिक वेबसाइट स्वयं खोलें। पॉप-अप नंबर पर भरोसा न करें और अनचाही कॉल को रिमोट एक्सेस न दें।",
            },
            "te": {
                "scam": "తీవ్రమైన వైరస్ గుర్తించబడింది! స్క్రీన్‌లోని సపోర్ట్ నంబర్‌కు కాల్ చేసి {time} {amount} చెల్లించండి; ఈ హెచ్చరికను మూసివేయవద్దు.",
                "genuine": "పరికర సహాయం కోసం తయారీదారు అధికారిక సైట్‌ను మీరే తెరవండి. పాప్-అప్ నంబర్‌ను నమ్మవద్దు; అనుకోని కాలర్‌కు రిమోట్ యాక్సెస్ ఇవ్వవద్దు.",
            },
        },
    },
    {
        "pattern": "fake_loan_recovery",
        "title": "Fake Loan Approval or Recovery Fee",
        "overview": "A supposed lender or recovery agent promises instant approval or threatens action and asks for an advance processing fee, OTP, remote access, or payment to a personal account. Verify the lender and any outstanding balance directly with the regulated provider.",
        "source": "I4C",
        "severity": "HIGH",
        "signals": {
            "en": "A lender demands an advance fee, OTP, or payment to a personal account to approve or close a loan.",
            "hi": "कर्ज मंजूर या बंद करने के लिए अग्रिम शुल्क, OTP या निजी खाते में भुगतान मांगा जाता है।",
            "te": "రుణం మంజూరు లేదా ముగింపు కోసం ముందస్తు ఫీజు, OTP లేదా వ్యక్తిగత ఖాతాకు చెల్లింపు అడుగుతారు.",
        },
        "messages": {
            "en": {
                "scam": "Your loan of {amount} is approved if you pay the release fee {time}. Send the OTP and fee to this personal account.",
                "genuine": "Your loan statement is available in the lender's official app. Review the balance and contact the provider using its published support details if anything is unclear.",
            },
            "hi": {
                "scam": "{time} रिलीज़ शुल्क देने पर {amount} का कर्ज मंजूर है। OTP और शुल्क इस निजी खाते में भेजें।",
                "genuine": "आपका कर्ज विवरण ऋणदाता के आधिकारिक ऐप में उपलब्ध है। बकाया जांचें और सवाल होने पर प्रकाशित सहायता विवरण से संपर्क करें।",
            },
            "te": {
                "scam": "{time} విడుదల ఫీజు చెల్లిస్తే {amount} రుణం మంజూరు. OTP, ఫీజును ఈ వ్యక్తిగత ఖాతాకు పంపండి.",
                "genuine": "మీ రుణ స్టేట్‌మెంట్ రుణదాత అధికారిక యాప్‌లో ఉంది. బాకీని పరిశీలించి సందేహాలుంటే ప్రచురించిన సపోర్ట్ వివరాలతో సంస్థను సంప్రదించండి.",
            },
        },
    },
]

GENUINE_CATEGORIES = {
    "accidental_transfer": "payment_notice_genuine",
    "electricity_disconnection": "utility_notice_genuine",
    "lottery_scam": "contest_notice_genuine",
    "customs_fee_scam": "delivery_notice_genuine",
    "sim_swap": "carrier_notice_genuine",
    "remote_access_scam": "support_notice_genuine",
    "romance_scam": "personal_request_genuine",
    "task_job_scam": "job_notice_genuine",
    "deepfake_impersonation": "identity_check_genuine",
    "upi_collect_request": "upi_payment_genuine",
    "money_mule_recruitment": "employment_notice_genuine",
    "crypto_recovery_scam": "wallet_security_genuine",
    "social_media_account_recovery": "account_security_genuine",
    "tech_support_scam": "device_support_genuine",
    "fake_loan_recovery": "loan_notice_genuine",
}

def _localized_indicators(pattern):
    return [
        pattern["signals"][language]
        for language in ("en", "hi", "te")
    ]


def _make_rows(pattern):
    rows = []
    for language in ("en", "hi", "te"):
        localized = pattern["messages"][language]
        for label, category_suffix in (("scam", None), ("genuine", "genuine")):
            category = (
                pattern["pattern"]
                if category_suffix is None
                else GENUINE_CATEGORIES[pattern["pattern"]]
            )
            for index, values in enumerate(VARIANTS[language], start=1):
                text = (
                    localized[label].format(**values)
                    + (
                        f" Reference {values['reference']}."
                        if language == "en"
                        else (
                            f" संदर्भ {values['reference']}।"
                            if language == "hi"
                            else f" రిఫరెన్స్ {values['reference']}."
                        )
                    )
                )
                source = SOURCES[pattern["source"]]
                is_scam = label == "scam"
                rows.append(
                    {
                        "sample_id": (
                            f"MSI-{pattern['pattern']}-{language}-"
                            f"{'S' if is_scam else 'G'}-{index:02d}"
                        ),
                        "text": text,
                        "label": label,
                        "scam_category": category,
                        "language": language,
                        "source": (
                            f"Guidance-informed synthetic illustration; "
                            f"{source['name']}"
                            if is_scam
                            else "ScamShield synthetic benign control"
                        ),
                        "data_origin": (
                            "official_guidance_paraphrase"
                            if is_scam
                            else "synthetic_control"
                        ),
                        "indicators": json.dumps(
                            [pattern["signals"][language]],
                            ensure_ascii=False,
                        ),
                        "expected_action": (
                            SAFE_ACTION[language]
                            if is_scam
                            else (
                                "Check the notice in the official app or account."
                                if language == "en"
                                else (
                                    "सूचना आधिकारिक ऐप या खाते में जांचें।"
                                    if language == "hi"
                                    else "అధికారిక యాప్ లేదా ఖాతాలో నోటీసును చూడండి."
                                )
                            )
                        ),
                        "resolution_steps": json.dumps(
                            RESOLUTION_STEPS[language],
                            ensure_ascii=False,
                        ),
                        "severity": "HIGH" if is_scam else "LOW",
                        "priority": "P1" if is_scam else "P3",
                        "notes": (
                            "Guidance-informed generated example; not an observed message or victim report."
                            if is_scam
                            else "Generated benign control; not an observed message."
                        ),
                        "input_channel": "text",
                    }
                )
    return rows


def _make_article(pattern, rows):
    source = SOURCES[pattern["source"]]
    examples = []
    for language in ("en", "hi", "te"):
        language_rows = [
            row
            for row in rows
            if row["language"] == language and row["label"] == "scam"
        ]
        for row in (language_rows[0], language_rows[-1]):
            examples.append(
                {
                    "sample_id": row["sample_id"],
                    "text": row["text"],
                    "language": language,
                    "provenance": "synthetic_illustration_not_observed",
                    "input_channel": "text",
                    "source": "ScamShield generated educational illustration",
                }
            )

    return {
        "article_id": f"SCAM-EXT-{pattern['pattern'].upper()}",
        "title": pattern["title"],
        "pattern": pattern["pattern"],
        "type": "scam_pattern",
        "label": "scam",
        "overview": pattern["overview"],
        "common_indicators": _localized_indicators(pattern),
        "recommended_action": [SAFE_ACTION[language] for language in ("en", "hi", "te")],
        "resolution_steps": [
            step
            for language in ("en", "hi", "te")
            for step in RESOLUTION_STEPS[language]
        ],
        "severity": [pattern["severity"]],
        "priority": ["P1"],
        "representative_examples": examples,
        "dataset_record_count": sum(row["label"] == "scam" for row in rows),
        "source_basis": [
            "ScamShield multilingual dataset; guidance-informed synthetic illustrations",
            source["name"],
        ],
        "research_note": (
            "Examples are generated educational scenarios informed by general official safety guidance, "
            "not copied advisories, verified incidents, or victim-submitted messages. Severity and priority "
            "are ScamShield policy labels, not externally validated probabilities."
        ),
        "source_reference": source["url"],
        "languages_supported": ["en", "hi", "te"],
        "languages_in_examples": ["en", "hi", "te"],
    }


def extend_data():
    with DATASET_PATH.open(encoding="utf-8-sig", newline="") as dataset_file:
        reader = csv.DictReader(dataset_file)
        fieldnames = reader.fieldnames
        if not fieldnames:
            raise ValueError(f"Dataset has no CSV header: {DATASET_PATH}")
        dataset_rows = list(reader)

    with KNOWLEDGE_PATH.open(encoding="utf-8") as knowledge_file:
        knowledge_base = json.load(knowledge_file)

    existing_ids = {row["sample_id"] for row in dataset_rows}
    existing_texts = {row["text"] for row in dataset_rows}
    existing_article_ids = {
        article["article_id"] for article in knowledge_base["articles"]
    }
    added_rows = []
    added_articles = []

    for pattern in PATTERNS:
        rows = _make_rows(pattern)
        article = _make_article(pattern, rows)
        if article["article_id"] in existing_article_ids:
            raise ValueError(
                f"Refusing to overwrite knowledge article {article['article_id']}"
            )
        for row in rows:
            if row["sample_id"] in existing_ids or row["text"] in existing_texts:
                raise ValueError(
                    f"Generated sample conflicts with existing data: {row['sample_id']}"
                )
            if set(row) != set(fieldnames):
                raise ValueError("Generated dataset columns do not match the CSV schema")
            existing_ids.add(row["sample_id"])
            existing_texts.add(row["text"])
            added_rows.append(row)
        added_articles.append(article)

    combined_rows = dataset_rows + added_rows
    labels = {label: sum(row["label"] == label for row in combined_rows) for label in ("scam", "genuine")}
    if labels["scam"] != labels["genuine"]:
        raise ValueError(f"Dataset class counts would be unbalanced: {labels}")
    if any(not value.strip() for row in combined_rows for value in row.values()):
        raise ValueError("Dataset contains a missing or blank field")

    knowledge_base["articles"].extend(added_articles)
    knowledge_base["article_counts"] = {
        "scam_patterns": sum(a["type"] == "scam_pattern" for a in knowledge_base["articles"]),
        "genuine_patterns": sum(a["type"] == "genuine_pattern" for a in knowledge_base["articles"]),
        "total_articles": len(knowledge_base["articles"]),
    }
    knowledge_base["version"] = "3.1"
    knowledge_base["source_dataset"] = (
        f"{DATASET_PATH.name} ({len(combined_rows):,} samples; "
        "synthetic, user-reference, and official-guidance-paraphrase origins)"
    )

    with DATASET_PATH.open("w", encoding="utf-8-sig", newline="") as dataset_file:
        writer = csv.DictWriter(dataset_file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(combined_rows)
    with KNOWLEDGE_PATH.open("w", encoding="utf-8", newline="\n") as knowledge_file:
        json.dump(knowledge_base, knowledge_file, ensure_ascii=False, indent=2)
        knowledge_file.write("\n")

    print(
        f"Added {len(added_rows)} multilingual records and {len(added_articles)} "
        f"scam articles; dataset now has {len(combined_rows)} rows."
    )


if __name__ == "__main__":
    extend_data()
