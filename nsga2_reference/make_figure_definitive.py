"""Figura definitiva. Fontes exclusivas: curves_all.json e reference_points.csv.
Nenhum numero escrito a mao."""
import json, csv, numpy as np, matplotlib
matplotlib.use('Agg'); import matplotlib.pyplot as plt
# Fontes TrueType incorporadas (fonttype 42): evita Type 3, que alguns
# sistemas de preflight editorial sinalizam ou rejeitam.
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42
NF=578
cur=json.load(open('curves_all.json')); ref=list(csv.DictReader(open('reference_points.csv')))
COL={20:'#86b6ef',50:'#5598e7',100:'#2a78d6',200:'#1c5cab',600:'#0d366b'}
fig,(ax,bx)=plt.subplots(1,2,figsize=(10.6,4.3),gridspec_kw={'width_ratios':[1.75,1]})

for pop in (20,50,100,200,600):
    d=cur[f"rand_{pop}"]; x=np.array(d['x'])
    ax.fill_between(x,np.array(d['q1'])/NF*100,np.array(d['q3'])/NF*100,color=COL[pop],alpha=.16,lw=0)
    ax.plot(x,np.array(d['med'])/NF*100,color=COL[pop],lw=1.7 if pop==100 else 1.3,
            zorder=3 if pop==100 else 2)
    ax.annotate(f"pop {pop}"+(" *" if pop==20 else ""),(x[-1],d['med'][-1]/NF*100),
                xytext=(5,-1),textcoords='offset points',color=COL[pop],fontsize=8,va='center',
                fontweight='bold' if pop==100 else 'normal')
ax.axhline(max(float(r['recall']) for r in ref)*100,color='#eb6834',lw=1,ls='--',alpha=.5)
for r in ref: ax.plot(int(r['n_new']),float(r['recall'])*100,'o',color='#eb6834',ms=6,mec='white',mew=1.2,zorder=5)
D={r['variant']:r for r in ref}
ax.annotate('CC-DNR / Full',(int(D['Full']['n_new']),float(D['Full']['recall'])*100),
            xytext=(11,-3),textcoords='offset points',color='#eb6834',fontsize=8)
ax.annotate('Fixed',(int(D['Fixed']['n_new']),float(D['Fixed']['recall'])*100),
            xytext=(-4,-13),textcoords='offset points',color='#eb6834',fontsize=8,ha='right')
ax.set_xlim(0,21800); ax.set_ylim(0,102)
ax.set_xlabel('new evaluations (cache misses; distinct decisions)',fontsize=9)
ax.set_ylabel('exact Pareto decisions recovered (%)',fontsize=9)
ax.set_title('(a) population sensitivity; bold = pop 100 baseline',loc='left',fontsize=8.5,color='#52514e')
for s in ('top','right'): ax.spines[s].set_visible(False)
ax.grid(axis='y',color='#e6e5e1',lw=.8); ax.set_axisbelow(True); ax.tick_params(labelsize=8)

# painel (b): controlo de inicializacao
for pop,ls in ((50,'--'),(100,'-')):
    for tag,c in (("halton",'#eb6834'),("paired",'#2a78d6')):
        d=cur[f"{tag}_{pop}"]; x=np.array(d['x'])
        bx.plot(x,np.array(d['med'])/NF*100,color=c,lw=1.5,ls=ls,
                label=f"{tag} pop {pop}")
bx.set_xlim(0,20500); bx.set_ylim(0,102)
bx.set_xlabel('new evaluations',fontsize=9)
bx.set_title('(b) initialization control: Halton vs paired random',loc='left',fontsize=8.5,color='#52514e')
bx.legend(fontsize=7.5,frameon=False,loc='upper left')
for s in ('top','right'): bx.spines[s].set_visible(False)
bx.grid(axis='y',color='#e6e5e1',lw=.8); bx.set_axisbelow(True); bx.tick_params(labelsize=8)

fig.suptitle('MORAP-NM: mixed-variable NSGA-II (pymoo 0.6.2) vs published DMS-SI-Mix poll variants.  '
             'Median of 30 seeds, IQR band.  * pop 20 never reached 20,000 distinct evaluations.',
             fontsize=8,color='#52514e',x=.012,ha='left',y=.995)
fig.tight_layout(rect=[0,0,1,.955])
fig.savefig('Fig_MORAP_NM_definitive.pdf'); fig.savefig('Fig_MORAP_NM_definitive.png',dpi=170)
print('ok')
